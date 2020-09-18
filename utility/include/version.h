#ifndef __VERSION_H__
#define __VERSION_H__

/*
 *  @ ver 2.0 - First version
 *  @ ver 2.1 - Add exit signal function
 *  @ ver 2.2 - Turn EMUCOpenDevice to EMUCOpenSocketCAN
 *  @ ver 2.3 - Add 400K baudrate
 *  @ ver 2.4 - Separate debug message (daemon & foreground), add more debug message
 *  @ ver 2.5 - Add INNO_XMIT_DELAY_CMD ioctl command
 *              (only for channel-1 baudrate, set ch1 & ch2 to the same baud is advised)
 *  @ ver 2.6 - Add open COM port timeout
 *  @ ver 2.7 - Mark "emuc active from utility"
 *            - must use SocketCAN driver >= ver 2.5
 *            - EMUC device will auto active after setting up "two" CAN port
 *            - modify run_emucd: check emuc_64, ip link successfully
 *
 */

#define  EMUC_DAEMON_UTILITY_VERSION  "v2.7"

#endif