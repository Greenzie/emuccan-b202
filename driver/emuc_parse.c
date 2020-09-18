#include <linux/string.h>
#include <linux/module.h>

#include "emuc_parse.h"

#if _DBG_FUNC
extern void print_func_trace (int line, const char *func);
#endif

static void chk_sum_end_byte (unsigned char *frame, int size);


/*---------------------------------------------------------------------------------------*/
void EMUCSendHex (EMUC_CAN_FRAME *frame)
{
  unsigned char  *p;
  unsigned char   func = 0x00;

#if _DBG_FUNC
  print_func_trace(__LINE__, __FUNCTION__);
#endif

  p = frame->com_buf;
  memset(p, 0, sizeof(frame->com_buf));

  /* head - byte 0 */
  *p = CMD_HEAD_SEND;

  /* func - byte 1 */
  func += frame->CAN_port + 1;
  func += ((frame->id_type - 1) << 2);
  func += frame->rtr << 3;
  func += frame->dlc << 4;

  *(p+1) = func;

  /* id - byte 2 ~ byte 5 */
  memcpy(p+2, frame->id, ID_LEN);

  /* data - byte 6 ~ byte 13 */
  memcpy(p+6, frame->data, DATA_LEN);

  /* chk sum & end byte - byte 14 ~ byte 16 */
  chk_sum_end_byte(p, COM_BUF_LEN);
}

/*---------------------------------------------------------------------------------------*/
int EMUCRevHex (EMUC_CAN_FRAME *frame)
{
  int             i;
  unsigned char   chk_sum = 0x00;
  unsigned char  *p;

#if _DBG_FUNC
  print_func_trace(__LINE__, __FUNCTION__);
#endif

  p = frame->com_buf;

#if _DBG_RECV_HEX
/*--------------------------------------*/
  for(i=0; i<COM_BUF_LEN; i++)
    printk("%02X ", *(p + i));
  printk("\n");
/*--------------------------------------*/
#endif

  /* head - byte 0 */
  if(*p != CMD_HEAD_RECV)
    return -1;

  /* check sum - byte 14 */
  for(i=0; i<COM_BUF_LEN-3; i++)
    chk_sum = chk_sum + *(p + i);

  if(chk_sum != *(p+14))
    return -2;

  /* func - byte 1 */
  frame->CAN_port = ((int) ( *(p+1) & 0x03)) - 1;
  frame->id_type  = ((int) ((*(p+1) & 0x04) >> 2)) + 1;
  frame->rtr      =  (int) ((*(p+1) & 0x08) >> 3);
  frame->dlc      =  (int) ((*(p+1) & 0xF0) >> 4);

  /* id - byte 2 ~ byte 5 */
  memcpy(frame->id, p+2, ID_LEN);

  /* data - byte 6 ~ byte 13 */
  memcpy(frame->data, p+6, DATA_LEN);

  return 0;

} /* END: EMUCRevHex() */

/*---------------------------------------------------------------------------------------*/
void EMUCInitHex (int sts, unsigned char *cmd)
{
#if _DBG_FUNC
  print_func_trace(__LINE__, __FUNCTION__);
#endif

  *(cmd+1) = sts;
  *(cmd+2) = sts;
  *(cmd+3) = *(cmd+0) + *(cmd+1) + *(cmd+2);

  return;

} /* END: EMUCInitHex() */

/*---------------------------------------------------------------------------------------*/
static void chk_sum_end_byte (unsigned char *frame, int size)
{
  int            i;
  unsigned char  chk_sum = 0x00;

#if _DBG_FUNC
  print_func_trace(__LINE__, __FUNCTION__);
#endif

  for(i=0; i<size-3; i++)
    chk_sum = chk_sum + *(frame + i);

  *(frame + size - 3) = chk_sum;
  *(frame + size - 2) = 0x0D;
  *(frame + size - 1) = 0x0A;
}