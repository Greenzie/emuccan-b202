#ifndef __TRANSCEIVE_H__
#define __TRANSCEIVE_H__


#include <linux/can.h>
#include <linux/workqueue.h>
#include <linux/netdevice.h>


#include "emuc_parse.h"


/* maximum rx buffer len: extended CAN frame with timestamp */
#define   EMUC_MTU    17
#define   EMUC_MAGIC  0x729B


/*--------------------------------------------------------------*/
typedef struct
{
  int      magic;

  /* Various fields. */
  struct tty_struct  *tty;              /* ptr to TTY structure      */
  struct net_device  *devs[2];          /* easy for intr handling    */
  spinlock_t          lock;
  struct work_struct  tx_work;          /* Flushes transmit buffer   */
  atomic_t            ref_count;        /* reference count           */
  int                 gif_channel;      /* index for SIOCGIFNAME     */
  unsigned char       current_channel;  /* Record current channel: for fixing tx_packet bug (v2.2) */

  /* These are pointers to the malloc()ed frame buffers. */
  unsigned char       rbuff[EMUC_MTU];  /* receiver buffer           */
  int                 rcount;           /* received chars counter    */
  unsigned char       xbuff[EMUC_MTU];  /* transmitter buffer        */
  unsigned char      *xhead;            /* pointer to next XMIT byte */
  int                 xleft;            /* bytes left in XMIT queue  */
  unsigned long       flags;            /* Flag values/ mode etc     */

  #define  SLF_INUSE  0                 /* Channel in use            */
  #define  SLF_ERROR  1                 /* Parity, etc. error        */

} EMUC_RAW_INFO;



/*--------------------------------------------------------------*/
typedef struct
{
  int             magic;
  EMUC_RAW_INFO  *info;    /* just ptr to emuc_info */

} EMUC_PRIV;


/*--------------------------------------------------------------*/
void emuc_unesc   (EMUC_RAW_INFO *info, unsigned char s);
void emuc_bump    (EMUC_RAW_INFO *info);
void emuc_encaps  (EMUC_RAW_INFO *info, int channel, struct can_frame *cf);
void emuc_transmit(struct work_struct *work);
void emuc_initCAN (EMUC_RAW_INFO *info, int sts);



#endif