/************************************************************************
Lab 9 Nios Software

Dong Kai Wang, Fall 2017
Christine Chen, Fall 2013

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "aes.h"

// Pointer to base address of AES module, make sure it matches Qsys
volatile unsigned int * AES_PTR = (unsigned int *) 0x08001040;

// Execution mode: 0 for testing, 1 for benchmarking
int run_mode = 0;

//################ DEFINING HELPER FUNCTIONS ##########################
void leftWord(unsigned char * word)
{
 	unsigned char temp = word[0];
	for(int i=0; i<3; i++)
		word[i]= word[i+1];

 	word[3] = temp;	//left shifting the word
}

 void subWord(unsigned char * word){
 	for(int i = 0;i<4;i++)
 		word[i] = aes_sbox[word[i]];    //substituting from the loopup table
}

void Rcon_word(unsigned char * roundKey, int idx){
	unsigned int temp = Rcon[idx];

	unsigned char rcon_temp[sizeof(temp)];
	memcpy(&rcon_temp, &temp, sizeof(temp));

 	roundKey[0] =roundKey[0] ^ rcon_temp[3];

}

void KeyExpansions(unsigned char * key, unsigned char * keySchedule){

	for(int i = 0;i<16;i++)
		keySchedule[i] = key[i];

    int roundKey =1;
	unsigned char temp_word[4];

	for(int i = 4; i<44; i++){
		int idx = i*4;
        for(int j=0;j<4;j++)
			temp_word[j]=keySchedule[idx+j-4];

		if(idx%16==0){
			rotWord(temp_word);
			subWord(temp_word);
			Rcon_word(temp_word,roundKey);
			roundKey++;
		}

		for(int j=0;j<4;j++)
			keySchedule[idx+j]=keySchedule[idx+j-16]^temp_word[j];
	}
    // for(int i=0; i<44;i++){
    //     printf("Key Expansion %x/n", keySchedule)
    // }
}

void Round_Keyschedule(unsigned char * message_st, unsigned char * roundKey){
    for(int i=0;i<16;i++)
 		message_st[i]=message_st[i]^roundKey[i];  //XOR the key and the state ofe the final output
}

void SubBytes(unsigned char * message_st){
 	for(int i = 0;i<16;i++)
 		message_st[i] = aes_sbox[message_st[i]];  //substituing bytes of the state from the look table provided
}

void ShiftRows(unsigned char * message_st){
 	uchar temp_state[16];
	int idx;

	for(int i=0; i<16; i++){    //row i/4 is shifted i%4 times

		if(i==0 || i==4|| i==8|| i==12){
			idx=i;
			temp_state[i] = message_st[idx];
		}

        if(i==2 || i==6|| i==10|| i==14){
			idx=(i+8)%16;
			temp_state[i] = message_st[idx];
		}

		if(i==1 || i==5|| i==9|| i==13){
			idx=(i+4)%16;
			temp_state[i] = message_st[idx];
		}

		if(i==3 || i==7|| i==11|| i==15){
			idx=(i+12)%16;
			temp_state[i]= message_st[idx];
		}
    }

 	for(int i = 0; i <16;i++)   //assigning the current state the right vals
 		message_st[i]=temp_state[i];
}


void MixCol(unsigned char *col ){

	unsigned char temp_col[16];
	int idx, col0, col1, col2, col3;

	for (int j =0; j<4; j++){
		for(int i=0; i<4; i++){
			idx = j+(4*i);
			col0= 4*i;
			col1= col0+1;
			col2 = col1+1;
			col3 = col2+1;

			if(j==0)
				temp_col[idx] = gf_mul[col[col0]][0] ^ gf_mul[col[col1]][1] ^ col[col2] ^ col[col3];

			else if(j==1)
				temp_col[idx] = col[col0] ^ gf_mul[col[col1]][0] ^ gf_mul[col[col2]][1] ^ col[col3];

			else if(j==2)
				temp_col[idx] = col[col0] ^ col[col1] ^ gf_mul[col[col2]][0] ^ gf_mul[col[col3]][1];

			else if(j==3)
				temp_col[idx] = gf_mul[col[col0]][1] ^ col[col1] ^ col[col2] ^ gf_mul[col[col3]][0];

			}
	}

	for(int i = 0; i<16; i++)
	    col[i] = temp_col[i];
}



//################ HELPER FUNCTIONS END ##########################

/** charToHex
 *  Convert a single character to the 4-bit value it represents.
 *
 *  Input: a character c (e.g. 'A')
 *  Output: converted 4-bit value (e.g. 0xA)
 */
char charToHex(char c)
{
	char hex = c;

	if (hex >= '0' && hex <= '9')
		hex -= '0';
	else if (hex >= 'A' && hex <= 'F')
	{
		hex -= 'A';
		hex += 10;
	}
	else if (hex >= 'a' && hex <= 'f')
	{
		hex -= 'a';
		hex += 10;
	}
	return hex;
}

/** charsToHex
 *  Convert two characters to byte value it represents.
 *  Inputs must be 0-9, A-F, or a-f.
 *
 *  Input: two characters c1 and c2 (e.g. 'A' and '7')
 *  Output: converted byte value (e.g. 0xA7)
 */
char charsToHex(char c1, char c2)
{
	char hex1 = charToHex(c1);
	char hex2 = charToHex(c2);
	return (hex1 << 4) + hex2;
}

/** encrypt
 *  Perform AES encryption in software.
 *
 *  Input: msg_ascii - Pointer to 32x 8-bit char array that contains the input message in ASCII format
 *         key_ascii - Pointer to 32x 8-bit char array that contains the input key in ASCII format
 *  Output:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *               key - Pointer to 4x 32-bit int array that contains the input key
 */
void encrypt(unsigned char * msg_ascii, unsigned char * key_ascii, unsigned int * msg_enc, unsigned int * key)
{
	// Implement this function
	unsigned char message_state[16];
	unsigned char cipher_key[16];

    //converting ascii values to hex values
	for(int i = 0;i<16;i++){    //for the array of 16
		message_state[i] = charsToHex(msg_ascii[i*2],msg_ascii[(i*2)+1]);
		cipher_key[i] = charsToHex(key_ascii[i*2],key_ascii[(i*2)+1]);
	}

	unsigned char key_schedule[176];

	KeyExpansions(cipher_key,key_schedule);

	Round_Keyschedule(message_state,key_schedule);


	for(int i=0;i<9;i++){
		SubBytes(message_state);

		ShiftRows(message_state);

		MixCol(message_state);

		Round_Keyschedule(message_state,key_schedule+(16*(i+1)));
	}


	SubBytes(message_state);

	ShiftRows(message_state);

	Round_Keyschedule(message_state,key_schedule+(16*10));    //dont mix columns the last time


	for(int i = 0;i<16;i=i+4){  //convert the message and key into unsinged char
		msg_enc[i/4]=(message_state[i]<<24) + (message_state[i+1]<<16) +(message_state[i+2]<<8) + message_state[i+3];
		key[i/4]=(cipher_key[i]<<24) + (cipher_key[i+1]<<16) +(cipher_key[i+2]<<8) + cipher_key[i+3];
	}
}

/** decrypt
 *  Perform AES decryption in hardware.
 *
 *  Input:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *              key - Pointer to 4x 32-bit int array that contains the input key
 *  Output: msg_dec - Pointer to 4x 32-bit int array that contains the decrypted message
 */
void decrypt(unsigned int * msg_enc, unsigned int * msg_dec, unsigned int * key)
{
	// Implement this function
	//	printf("Reached decrypt\n");
	AES_PTR[0] = key[0];
	AES_PTR[1] = key[1];
	AES_PTR[2] = key[2];
	AES_PTR[3] = key[3];


	AES_PTR[4] = msg_enc[0];
	AES_PTR[5] = msg_enc[1];
	AES_PTR[6] = msg_enc[2];
	AES_PTR[7] = msg_enc[3];

	AES_PTR[14] =  1;


//	printf("Decrypt while loop starts\n");
	while(AES_PTR[15]==0){

		}
//	printf("Decrypt while loop ends\n");

	AES_PTR[14]=0;
	msg_dec[3] = AES_PTR[8];
	msg_dec[2] = AES_PTR[9];
	msg_dec[1] = AES_PTR[10];
	msg_dec[0] = AES_PTR[11];

	AES_PTR[14] =  0;   //goes back to halt
//	printf("Decrypt ret called\n");
}

/** main
 *  Allows the user to enter the message, key, and select execution mode
 *
 */
int main()
{
	// Input Message and Key as 32x 8-bit ASCII Characters ([33] is for NULL terminator)
	unsigned char msg_ascii[33];
	unsigned char key_ascii[33];
	// Key, Encrypted Message, and Decrypted Message in 4x 32-bit Format to facilitate Read/Write to Hardware
	unsigned int key[4];
	unsigned int msg_enc[4];
	unsigned int msg_dec[4];

	printf("Select execution mode: 0 for testing, 1 for benchmarking: ");
	scanf("%d", &run_mode);

	if (run_mode == 0) {
		// Continuously Perform Encryption and Decryption
		while (1) {
			int i = 0;
			printf("\nEnter Message:\n");
			scanf("%s", msg_ascii);
			printf("\n");
			printf("\nEnter Key:\n");
			scanf("%s", key_ascii);
			printf("\n");
			encrypt(msg_ascii, key_ascii, msg_enc, key);
			printf("\nEncrpted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_enc[i]);
			}
			printf("\n");
			decrypt(msg_enc, msg_dec, key);
			printf("\nDecrypted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_dec[i]);
			}
			printf("\n");
		}
	}
	else {
		// Run the Benchmark
		int i = 0;
		int size_KB = 2;
		// Choose a random Plaintext and Key
		for (i = 0; i < 32; i++) {
			msg_ascii[i] = 'a';
			key_ascii[i] = 'b';
		}
		// Run Encryption
		clock_t begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			encrypt(msg_ascii, key_ascii, msg_enc, key);
		clock_t end = clock();
		double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		double speed = size_KB / time_spent;
		printf("Software Encryption Speed: %f KB/s \n", speed);
		// Run Decryption
		begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			decrypt(msg_enc, msg_dec, key);
		end = clock();
		time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		speed = size_KB / time_spent;
		printf("Hardware Encryption Speed: %f KB/s \n", speed);
	}
	return 0;
}
