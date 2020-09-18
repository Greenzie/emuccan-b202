#ifndef __EMUC_PARSE_H__
#define __EMUC_PARSE_H__



#define    ID_LEN           4
#define    DATA_LEN         8
#define    COM_BUF_LEN      17
#define    DATA_LEN_ERR     12
#define    TIME_CHAR_NUM    13
#define    CMD_HEAD_INIT    0x61
#define    CMD_HEAD_SEND    0xE0
#define    CMD_HEAD_RECV    0xE1

/*--------------------------------------*/
enum
{
  EMUC_CAN_1 = 0,
  EMUC_CAN_2
};

enum
{
  EMUC_SID = 1,
  EMUC_EID
};

enum
{
  EMUC_INACTIVE = 0,
  EMUC_ACTIVE
};


/*--------------------------------------*/
typedef struct
{
  int            CAN_port;
  int            id_type;
  int            rtr;
  int            dlc;

  unsigned char  id      [ID_LEN];
  unsigned char  data    [DATA_LEN];
  unsigned char  com_buf [COM_BUF_LEN];

} EMUC_CAN_FRAME;


/*--------------------------------------*/
void EMUCSendHex(EMUC_CAN_FRAME *frame);
int  EMUCRevHex (EMUC_CAN_FRAME *frame);
void EMUCInitHex(int sts, unsigned char *cmd);




#endif