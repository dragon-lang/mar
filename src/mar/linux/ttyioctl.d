module mar.linux.ttyioctl;

import mar.octal;
import mar.linux.file : FileD;
import mar.linux.ioctl : ioctl, _IO, _IOR, _IOW;

alias cc_t     = ubyte;
alias speed_t  = uint;
alias tcflag_t = uint;
enum NCCS = 19;

struct termios
{
    tcflag_t c_iflag;   // input mode flags
    tcflag_t c_oflag;   // output mode flags
    tcflag_t c_cflag;   // control mode flags
    tcflag_t c_lflag;   // local mode flags
    cc_t c_line;        // line discipline
    cc_t[NCCS] c_cc;    // control characters
}

struct termios2 {
    tcflag_t c_iflag;   // input mode flags
    tcflag_t c_oflag;   // output mode flags
    tcflag_t c_cflag;   // control mode flags
    tcflag_t c_lflag;   // local mode flags
    cc_t c_line;        // line discipline
    cc_t[NCCS] c_cc;    // control characters
    speed_t c_ispeed;   // input speed
    speed_t c_ospeed;   // output speed
};

struct ktermios {
    tcflag_t c_iflag;   // input mode flags
    tcflag_t c_oflag;   // output mode flags
    tcflag_t c_cflag;   // control mode flags
    tcflag_t c_lflag;   // local mode flags
    cc_t c_line;        // line discipline
    cc_t[NCCS] c_cc;    // control characters
    speed_t c_ispeed;   // input speed
    speed_t c_ospeed;   // output speed
};

// c_cc characters
enum VINTR    = 0;
enum VQUIT    = 1;
enum VERASE   = 2;
enum VKILL    = 3;
enum VEOF     = 4;
enum VTIME    = 5;
enum VMIN     = 6;
enum VSWTC    = 7;
enum VSTART   = 8;
enum VSTOP    = 9;
enum VSUSP    = 10;
enum VEOL     = 11;
enum VREPRINT = 12;
enum VDISCARD = 13;
enum VWERASE  = 14;
enum VLNEXT   = 15;
enum VEOL2    = 16;

// c_iflag bits
enum IGNBRK  = octalHex!0x000001;
enum BRKINT  = octalHex!0x000002;
enum IGNPAR  = octalHex!0x000004;
enum PARMRK  = octalHex!0x000010;
enum INPCK   = octalHex!0x000020;
enum ISTRIP  = octalHex!0x000040;
enum INLCR   = octalHex!0x000100;
enum IGNCR   = octalHex!0x000200;
enum ICRNL   = octalHex!0x000400;
enum IUCLC   = octalHex!0x001000;
enum IXON    = octalHex!0x002000;
enum IXANY   = octalHex!0x004000;
enum IXOFF   = octalHex!0x010000;
enum IMAXBEL = octalHex!0x020000;
enum IUTF8   = octalHex!0x040000;

// c_oflag bits
enum OPOST    = octalHex!0x000001;
enum OLCUC    = octalHex!0x000002;
enum ONLCR    = octalHex!0x000004;
enum OCRNL    = octalHex!0x000010;
enum ONOCR    = octalHex!0x000020;
enum ONLRET   = octalHex!0x000040;
enum OFILL    = octalHex!0x000100;
enum OFDEL    = octalHex!0x000200;
enum NLDLY    = octalHex!0x000400;
enum   NL0    = octalHex!0x000000;
enum   NL1    = octalHex!0x000400;
enum CRDLY    = octalHex!0x003000;
enum   CR0    = octalHex!0x000000;
enum   CR1    = octalHex!0x001000;
enum   CR2    = octalHex!0x002000;
enum   CR3    = octalHex!0x003000;
enum TABDLY   = octalHex!0x014000;
enum   TAB0   = octalHex!0x000000;
enum   TAB1   = octalHex!0x004000;
enum   TAB2   = octalHex!0x010000;
enum   TAB3   = octalHex!0x014000;
enum  XTABS   = octalHex!0x014000;
enum BSDLY    = octalHex!0x020000;
enum   BS0    = octalHex!0x000000;
enum   BS1    = octalHex!0x020000;
enum VTDLY    = octalHex!0x040000;
enum   VT0    = octalHex!0x000000;
enum   VT1    = octalHex!0x040000;
enum FFDLY    = octalHex!0x100000;
enum   FF0    = octalHex!0x000000;
enum   FF1    = octalHex!0x100000;

// c_cflag bit meaning
enum CBAUD    = octalHex!0x010017;
enum  B0      = octalHex!0x000000;        // hang up
enum  B50     = octalHex!0x000001;
enum  B75     = octalHex!0x000002;
enum  B110    = octalHex!0x000003;
enum  B134    = octalHex!0x000004;
enum  B150    = octalHex!0x000005;
enum  B200    = octalHex!0x000006;
enum  B300    = octalHex!0x000007;
enum  B600    = octalHex!0x000010;
enum  B1200   = octalHex!0x000011;
enum  B1800   = octalHex!0x000012;
enum  B2400   = octalHex!0x000013;
enum  B4800   = octalHex!0x000014;
enum  B9600   = octalHex!0x000015;
enum  B19200  = octalHex!0x000016;
enum  B38400  = octalHex!0x000017;
enum EXTA     = B19200;
enum EXTB     = B38400;
enum CSIZE    = octalHex!0x000060;
enum   CS5    = octalHex!0x000000;
enum   CS6    = octalHex!0x000020;
enum   CS7    = octalHex!0x000040;
enum   CS8    = octalHex!0x000060;
enum CSTOPB   = octalHex!0x000100;
enum CREAD    = octalHex!0x000200;
enum PARENB   = octalHex!0x000400;
enum PARODD   = octalHex!0x001000;
enum HUPCL    = octalHex!0x002000;
enum CLOCAL   = octalHex!0x004000;
enum CBAUDEX  = octalHex!0x010000;
enum   BOTHER = octalHex!0x010000;
enum   B57600 = octalHex!0x010001;
enum  B115200 = octalHex!0x010002;
enum  B230400 = octalHex!0x010003;
enum  B460800 = octalHex!0x010004;
enum  B500000 = octalHex!0x010005;
enum  B576000 = octalHex!0x010006;
enum  B921600 = octalHex!0x010007;
enum B1000000 = octalHex!0x010010;
enum B1152000 = octalHex!0x010011;
enum B1500000 = octalHex!0x010012;
enum B2000000 = octalHex!0x010013;
enum B2500000 = octalHex!0x010014;
enum B3000000 = octalHex!0x010015;
enum B3500000 = octalHex!0x010016;
enum B4000000 = octalHex!0x010017;

// are all 3 of these supposed to be octal????
//enum CIBAUD      02003600000    // input baud rate
//enum CMSPAR      10000000000    // mark or space (stick) parity
//enum CRTSCTS     20000000000    // flow control

enum IBSHIFT   =   16;        // Shift from CBAUD to CIBAUD

// c_lflag bits
enum ISIG    = octalHex!0x000001;
enum ICANON  = octalHex!0x000002;
enum XCASE   = octalHex!0x000004;
enum ECHO    = octalHex!0x000010;
enum ECHOE   = octalHex!0x000020;
enum ECHOK   = octalHex!0x000040;
enum ECHONL  = octalHex!0x000100;
enum NOFLSH  = octalHex!0x000200;
enum TOSTOP  = octalHex!0x000400;
enum ECHOCTL = octalHex!0x001000;
enum ECHOPRT = octalHex!0x002000;
enum ECHOKE  = octalHex!0x004000;
enum FLUSHO  = octalHex!0x010000;
enum PENDIN  = octalHex!0x040000;
enum IEXTEN  = octalHex!0x100000;
enum EXTPROC = octalHex!0x200000;

// tcflow() and TCXONC use these
enum    TCOOFF  = 0;
enum    TCOON   = 1;
enum    TCIOFF  = 2;
enum    TCION   = 3;

// tcflush() and TCFLSH use these
enum    TCIFLUSH  =  0;
enum    TCOFLUSH  =  1;
enum    TCIOFLUSH =  2;

// tcsetattr uses these
enum    TCSANOW    =  0;
enum    TCSADRAIN  =  1;
enum    TCSAFLUSH  =  2;


// These are the most common definitions for tty ioctl numbers.
// Most of them do not use the recommended _IOC(), but there is
// probably some source code out there hardcoding the number,
// so we might as well use them for all new platforms.

// The architectures that use different values here typically
// try to be compatible with some Unix variants for the same
// architecture.

// 0x54 is just a magic number to make these relatively unique ('T')

enum TCGETS        = 0x5401;
enum TCSETS        = 0x5402;
enum TCSETSW       = 0x5403;
enum TCSETSF       = 0x5404;
enum TCGETA        = 0x5405;
enum TCSETA        = 0x5406;
enum TCSETAW       = 0x5407;
enum TCSETAF       = 0x5408;
enum TCSBRK        = 0x5409;
enum TCXONC        = 0x540A;
enum TCFLSH        = 0x540B;
enum TIOCEXCL      = 0x540C;
enum TIOCNXCL      = 0x540D;
enum TIOCSCTTY     = 0x540E;
enum TIOCGPGRP     = 0x540F;
enum TIOCSPGRP     = 0x5410;
enum TIOCOUTQ      = 0x5411;
enum TIOCSTI       = 0x5412;
enum TIOCGWINSZ    = 0x5413;
enum TIOCSWINSZ    = 0x5414;
enum TIOCMGET      = 0x5415;
enum TIOCMBIS      = 0x5416;
enum TIOCMBIC      = 0x5417;
enum TIOCMSET      = 0x5418;
enum TIOCGSOFTCAR  = 0x5419;
enum TIOCSSOFTCAR  = 0x541A;
enum FIONREAD      = 0x541B;
enum TIOCINQ       = FIONREAD;
enum TIOCLINUX     = 0x541C;
enum TIOCCONS      = 0x541D;
enum TIOCGSERIAL   = 0x541E;
enum TIOCSSERIAL   = 0x541F;
enum TIOCPKT       = 0x5420;
enum FIONBIO       = 0x5421;
enum TIOCNOTTY     = 0x5422;
enum TIOCSETD      = 0x5423;
enum TIOCGETD      = 0x5424;
enum TCSBRKP       = 0x5425;    // Needed for POSIX tcsendbreak()
enum TIOCSBRK      = 0x5427;  // BSD compatibility
enum TIOCCBRK      = 0x5428;  // BSD compatibility
enum TIOCGSID      = 0x5429;  // Return the session ID of FD
enum TCGETS2       = _IOR('T', 0x2A, termios2.sizeof);
enum TCSETS2       = _IOW('T', 0x2B, termios2.sizeof);
enum TCSETSW2      = _IOW('T', 0x2C, termios2.sizeof);
enum TCSETSF2      = _IOW('T', 0x2D, termios2.sizeof);
enum TIOCGRS485    = 0x542E;
//#ifndef TIOCSRS485
//enum TIOCSRS485    = 0x542F;
//#endif
enum TIOCGPTN     = _IOR('T', 0x30, uint.sizeof); // Get Pty Number (of pty-mux device)
enum TIOCSPTLCK   = _IOW('T', 0x31, int.sizeof);  // Lock/unlock Pty
enum TIOCGDEV     = _IOR('T', 0x32, uint.sizeof); // Get primary device node of /dev/console
enum TCGETX       = 0x5432;                     // SYS5 TCGETX compatibility
enum TCSETX       = 0x5433;
enum TCSETXF      = 0x5434;
enum TCSETXW      = 0x5435;
enum TIOCSIG      = _IOW('T', 0x36, int.sizeof);  // pty: generate signal
enum TIOCVHANGUP  = 0x5437;
enum TIOCGPKT     = _IOR('T', 0x38, int.sizeof);  // Get packet mode state
enum TIOCGPTLCK   = _IOR('T', 0x39, int.sizeof);  // Get Pty lock state
enum TIOCGEXCL    = _IOR('T', 0x40, int.sizeof);  // Get exclusive mode state
enum TIOCGPTPEER  = _IO('T', 0x41);               // Safely open the slave

enum FIONCLEX        = 0x5450;
enum FIOCLEX         = 0x5451;
enum FIOASYNC        = 0x5452;
enum TIOCSERCONFIG   = 0x5453;
enum TIOCSERGWILD    = 0x5454;
enum TIOCSERSWILD    = 0x5455;
enum TIOCGLCKTRMIOS  = 0x5456;
enum TIOCSLCKTRMIOS  = 0x5457;
enum TIOCSERGSTRUCT  = 0x5458; // For debugging only
enum TIOCSERGETLSR   = 0x5459; // Get line status register
enum TIOCSERGETMULTI = 0x545A; // Get multiport config
enum TIOCSERSETMULTI = 0x545B; // Set multiport config

enum TIOCMIWAIT      = 0x545C;    // wait for a change on serial input line(s)
enum TIOCGICOUNT     = 0x545D;    // read serial port inline interrupt counts

//
// Some arches already define FIOQSIZE due to a historical
// conflict with a Hayes modem-specific ioctl value.
//#ifndef FIOQSIZE
//# define FIOQSIZE    = 0x5460;
//#endif

// Used for packet mode
enum TIOCPKT_DATA        =  0;
enum TIOCPKT_FLUSHREAD   =  1;
enum TIOCPKT_FLUSHWRITE  =  2;
enum TIOCPKT_STOP        =  4;
enum TIOCPKT_START       =  8;
enum TIOCPKT_NOSTOP      = 16;
enum TIOCPKT_DOSTOP      = 32;
enum TIOCPKT_IOCTL       = 64;

enum TIOCSER_TEMT    = 0x01;    // Transmitter physically empty

auto tcgetattr(FileD fd, termios* arg)
{
    return ioctl(fd, TCGETS, arg);
}
