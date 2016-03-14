/*
 * Copyright (c) 2000 Silicon Graphics, Inc.  All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of version 2 of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it would be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Further, this software is distributed without any warranty that it is
 * free of the rightful claim of any third person regarding infringement
 * or the like.  Any license provided herein, whether implied or
 * otherwise, applies only to this software file.  Patent licenses, if
 * any, provided herein do not apply to combinations of this program with
 * other software, or any other product whatsoever.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Contact information: Silicon Graphics, Inc., 1600 Amphitheatre Pkwy,
 * Mountain View, CA  94043, or:
 *
 * http://www.sgi.com
 *
 * For further information regarding this notice, see:
 *
 * http://oss.sgi.com/projects/GenInfo/NoticeExplan/
 *
 */
/* $Id: fchown01.c,v 1.4 2009/10/26 14:55:46 subrata_modak Exp $ */
/**********************************************************
 *
 *    OS Test - Silicon Graphics, Inc.
 *
 *    TEST IDENTIFIER	: fchown01
 *
 *    EXECUTED BY	: anyone
 *
 *    TEST TITLE	: Basic test for fchown(2)
 *
 *    PARENT DOCUMENT	: usctpl01
 *
 *    TEST CASE TOTAL	: 1
 *
 *    WALL CLOCK TIME	: 1
 *
 *    CPU TYPES		: ALL
 *
 *    AUTHOR		: William Roske
 *
 *    CO-PILOT		: Dave Fenner
 *
 *    DATE STARTED	: 02/14/92
 *
 *    INITIAL RELEASE	: UNICOS 7.0
 *
 *    TEST CASES
 *
 * 	1.) fchown(2) returns...(See Description)
 *
 *    INPUT SPECIFICATIONS
 * 	The standard options for system call tests are accepted.
 *	(See the parse_opts(3) man page).
 *
 *    OUTPUT SPECIFICATIONS
 *
 *    DURATION
 * 	Terminates - with frequency and infinite modes.
 *
 *    SIGNALS
 * 	Uses SIGUSR1 to pause before test if option set.
 * 	(See the parse_opts(3) man page).
 *
 *    RESOURCES
 * 	None
 *
 *    ENVIRONMENTAL NEEDS
 *      No run-time environmental needs.
 *
 *    SPECIAL PROCEDURAL REQUIREMENTS
 * 	None
 *
 *    INTERCASE DEPENDENCIES
 * 	None
 *
 *    DETAILED DESCRIPTION
 *	This is a Phase I test for the fchown(2) system call.  It is intended
 *	to provide a limited exposure of the system call, for now.  It
 *	should/will be extended when full functional tests are written for
 *	fchown(2).
 *
 * 	Setup:
 * 	  Setup signal handling.
 *	  Pause for SIGUSR1 if option specified.
 *
 * 	Test:
 *	 Loop if the proper options are given.
 * 	  Execute system call
 *	  Check return code, if system call failed (return=-1)
 *		Log the errno and Issue a FAIL message.
 *	  Otherwise, Issue a PASS message.
 *
 * 	Cleanup:
 * 	  Print errno log and/or timing stats if options given
 *
 *
 *#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#**/
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <errno.h>
#include <string.h>
#include <signal.h>
#include "test.h"
#include "usctest.h"

void setup();
void cleanup();

char *TCID = "fchown01";
int TST_TOTAL = 1;

int fd;				/* file descriptor for fchown */

int main(int ac, char **av)
{
	int lc;
	char *msg;

	if ((msg = parse_opts(ac, av, NULL, NULL)) != NULL)
		tst_brkm(TBROK, NULL, "OPTION PARSING ERROR - %s", msg);

	setup();

	for (lc = 0; TEST_LOOPING(lc); lc++) {

		tst_count = 0;

		TEST(fchown(fd, geteuid(), getegid()));

		if (TEST_RETURN == -1)
			tst_resm(TFAIL | TTERRNO, "fchown failed");
		else if (STD_FUNCTIONAL_TEST)
			tst_resm(TPASS,
				 "fchown(fd, geteuid(), getegid()) "
				 "returned %ld", TEST_RETURN);
	}

	cleanup();

	tst_exit();
}

void setup()
{
	char fname[1024];

	tst_sig(FORK, DEF_HANDLER, cleanup);

	TEST_PAUSE;

	tst_tmpdir();

	sprintf(fname, "./tmpfile.%d", getpid());
	if ((fd = open(fname, O_RDWR | O_CREAT, 0700)) == -1)
		tst_brkm(TBROK | TERRNO, cleanup, "open failed");
}

void cleanup()
{
	close(fd);

	TEST_CLEANUP;

	tst_rmdir();
}
