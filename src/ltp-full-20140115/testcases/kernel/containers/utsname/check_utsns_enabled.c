/*
* Copyright (c) International Business Machines Corp., 2007
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
* the GNU General Public License for more details.
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*
* Author: Serge Hallyn <serue@us.ibm.com>
*
* uts namespaces were introduced around 2.6.19.  Kernels before that,
* assume they are not enabled.  Kernels after that, check for -EINVAL
* when trying to use CLONE_NEWUTS.
***************************************************************************/

#include <sys/utsname.h>
#include <sched.h>
#include <stdio.h>
#include "../libclone/libclone.h"
#include "test.h"

const char *TCID = "check_utsns_enabled";

int dummy(void *v)
{
	return 0;
}

int main(void)
{
	int pid;

	if (tst_kvercmp(2, 6, 19) < 0)
		return 1;

	pid = ltp_clone_quick(CLONE_NEWUTS, dummy, NULL);

	if (pid == -1) {
		perror("ltp_clone_quick");
		return 3;
	}
	return 0;
}
