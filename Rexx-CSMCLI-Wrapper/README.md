# Rexx CSMCLI wrapper

The **csmcliwr.rexx** is a wrapper for the CSMCLI executable program. Its primary goal is to provide a reliable program return code, to enable automation an easy indication whether a CSMCLI command was completed successfully or has a warning or error message code. The CSMCLI executable itself will always return RC=0 if the command was accepted by the CSM server, independent of the execution result. That makes it difficult for external automation flows to validate whether the CSMCLI was successfull. This Rexx wrapper will parse the responses for Error or Warning messages returned by executed commands and consolidate the findings in a program exit code. It will return RC=0 only if the issued command was accepted and the execution did not result in any Errors or Warnings.

The Rexx executable can be run from OMVS, TSO, batch jobs as well as on Windows command line if a Rexx Interpreter is installed. If a CSMCLI command should be executed from a batch job, you can run the wrapper Rexx with TSO background execution programs such as IKJEFT01, IKJEFT1A or IKJEFT1B.

**Note:** It is recommended to setup password-less CSMCLI execution for the user running the CSMCLI wrapper, otherwise fully automated CSMCLI execution is not possible. In order to review options for password less CSMCLI usage and other CSM automation considerations, please refer to the White Paper:

- [IBM Copy Services Manager Session automation](https://www.ibm.com/support/pages/ibm-copy-services-manager-session-automation)

---

## CSMCLI Wrapper usage

The Rexx program can be customized with default CSM servername/IP, a default CLI command as well as the default debug level. Those settings can also be changed dynamically by execution arguments. You need to customize the environment variables for proper CSMCLI execution. You should set the user HOME variable where CSMCLI will look for the authentication properties file. The PATH variable need to contain the path to the operating system binaries for some system commands required by the CSMCLI. It also should contain the PATH to the CSMCLI executable on your system.

**Important:**

The Wrapper cannot launch the CSMCLI console in interactive mode. Also any interactive prompts cannot be used by the wrapper, for example confirmation prompts or password prompts. 

## Optional Input Parameters

- **-debug lvl**: 
  0: No additional information (Default)
  1: Prefix output messages, timestamps, runtime information
  2: Print used environment settings the debug args parsing
- **All CSMCLI program arguments / commands:**
  See CSMCLI documentation for allowed arguments and commands.

## Return Codes

The CSMCLI wrapper program has following return codes:

- 0: The command was executed successfully and Message Code is Info type
- 4: The command was executed, but Message code is Warning type
- 8: The command was executed, but resulted in an Error message
- 12: The command could not be executed on the CSM server for any reason
- 16: System environment for program cannot be established

## Runtime Environment

The Rexx program can be executed either on a Windows Platform or on z/OS (TSO & Batch). The platform where it is executed needs to have a Rexx interpreter in place and the CSMCLI needs to be installed with an existing authentication properties file for the CSM user. The location of the authentication properties file can be declared in the program with the environment parameter for HOME.  
The program was tested on z/OS with embedded Rexx interpreter as well as on Windows with [Regina Rexx](https://regina-rexx.sourceforge.io/) installed. A different Rexx interpreter on Windows might require adoptions in the script for system specific functions (e.g. reading and setting environment variables for the CSMCLI).

Other platforms are not supported at this time.

### Execution via JCL

On z/OS, the Rexx program can be executed via Job Control Language, for example to be scheduled in batch processing. Following JCL example shows how to execute the program and pass execution parameters:

```
//*----------------------------------------------------
//* Execute the REXX exec under a TSO environment
//*----------------------------------------------------
// SET  EXEDSN=#HLQ.CSM.CNTL                <== UPDATE
//*----------------------------------------------------
//RUN      EXEC PGM=IKJEFT01
//SYSEXEC  DD DSN=&EXEDSN,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//* Concatenate multple parameter lines with - at end of line
//SYSTSIN  DD *
 %CSMCLIWR                                                  -
 -server servername                                         -
 -help csmcli
/*
//INPUT    DD *
/*
//                                                 
```

You need to update the Job card, EXECDSN variable with dataset where the Rexx executable is saved. The Rexx member name must be specified in the SYSTSIN statement accordingly. The Rexx program execution parameters can be defined in the SYSTSIN DD statement as well like it is shown in this exampple. Make sure to concatenate multiple parameter lines with the program member name line by using the dash ‘-‘.

# Invokation example

Following example is using the wrapper program in debug mode. It demonstrates the difference between the CSMCLI program RC=0 and the Wrapper program RC<>0 upon a CLI command that resulted in an Error Message from the server:

```
/u/username> csmcliwr.rexx -debug cmdsess -action flash DS-GM
-------------------------------------------------------------------------------
18:49:27:DEBUG: Parsed executions arguments:
18:49:27:DEBUG: PRG ARGS: -debug 1
18:49:27:DEBUG: CLI ARGS: -server 9.155.114.80
18:49:27:DEBUG: CLI CMD : cmdsess -action flash DS-GM
-------------------------------------------------------------------------------
18:49:27:DEBUG: Run command: csmcli.sh -server 9.155.114.80 cmdsess -action flash DS-GM
18:49:27:DEBUG: CSM server : 9.155.114.80
18:49:27:DEBUG: Local O/S  : TSO
18:49:27:DEBUG: Debug Level: 1
-------------------------------------------------------------------------------
18:49:27:DEBUG: CLICMD: csmcli.sh -server 9.155.114.80 cmdsess -action flash DS-GM
18:49:42:DEBUG: CLIOUT: IBM Copy Services Manager Command Line Interface (CLI)
18:49:42:DEBUG: CLIOUT:  Copyright 2007, 2015 IBM Corporation
18:49:42:DEBUG: CLIOUT:  CLI Client Version: 6.3.1.0, Build: a20211105-1425
18:49:42:DEBUG: CLIOUT:  Authentication file: /u/username/csm-cli/csmcli-auth.properties
18:49:42:DEBUG: CLIOUT:
18:49:42:DEBUG: CLIOUT: Connected to:
18:49:42:DEBUG: CLIOUT:  Server: 9.155.114.80     Port: 9560   UseREST: false
18:49:42:DEBUG: CLIOUT:  Server Version: 6.3.1.0, Build: a20211109-1034
18:49:42:DEBUG: CLIOUT:
18:49:42:DEBUG: CLIOUT:  IWNC1302E [Feb 4, 2022 6:49:42 PM] The action flash is not currently valid for this session; valid actions are: startgc_h1:h2, start_h1:h2, set_production_to_site_2.
18:49:42:DEBUG: Found Error Msg: IWNC1302E [Feb 4, 2022 6:49:42 PM] The action flash is not currently valid for this session; valid actions are: startgc_h1:h2, start_h1:h2, set_production_to_site_2.
18:49:42:DEBUG: CLIRC : 0
-------------------------------------------------------------------------------
18:49:42:DEBUG: CSMCLI  RC: 0
18:49:42:DEBUG: Program RC: 8
18:49:42:DEBUG: Error Msg : IWNC1302E [Feb 4, 2022 6:49:42 PM] The action flash is not currently valid for this session; valid actions are: startgc_h1:h2, start_h1:h2, set_production_to_site_2.
18:49:42:DEBUG: Runtime   : 0:06.2 (min:sec)
-------------------------------------------------------------------------------
```

---

# Copyright information and disclaimer

This program is licensed under the Apache License 2.0. You may 
obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

It is a permissive license whose main conditions require preservation of 
copyright and license notices. Contributors provide an express grant of 
patent rights. Licensed works, modifications, and larger works may be 
distributed under different terms and without source code.

The example is provided for tutorial purposes only. A complete handling 
of error conditions has not been shown or attempted, and this program has 
not been submitted to formal IBM testing. This program is distributed on an 
'AS IS' basis without any warranties either expressed or implied.

Copyright IBM Corporation 2022
