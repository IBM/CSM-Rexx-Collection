/* REXX */
/*****************************************************************************/
/* IBM Copy Services Manager CLI wrapper program:                            */
/* ----------------------------------------------                            */
/* It uses the CSMCLI installed in USS to run a CSMCLI command. The wrapper  */
/* analyses the return code and CSM messages to wrap this up in a program    */
/* return code. The CSMCLI output is also printed.                           */
/* All parameters supported by the CSMCLI executable programm can be         */
/* specified. The default CSMCLI executable & arguments, default CSM server  */
/* and default CLI command can be specified in this program. The username    */
/* and password can also be specified, but its recommended to provide them   */
/* via an encrypted authentication properties file in the program User HOME  */
/* directory (see environment settings below).                               */
/*                                                                           */
/* Additional Input parameters for this program:                             */
/* ---------------------------------------------                             */
/* -debug lvl: Specify whether additional debug information to be printed    */
/*          0: No additional information (Default)                           */
/*          1: Prefix output messages, timestamps, runtime information       */
/*          2: Print used environment settings the debug args parsing        */
/*                                                                           */
/* The program has following overall return codes:                           */
/* -----------------------------------------------                           */
/* 0 : The command was executed successfully and Message Code is Info type   */
/* 4 : The command was executed, but Message code is Warning type            */
/* 8 : The command was executed, but resulted in an Error message            */
/* 12: The command could not be executed on the CSM server for any reason    */
/* 16: System environment for program cannot be established                  */
/*****************************************************************************/
/* COPYRIGHT INFORMATION AND DISCLAIMER:                                     */
/* -------------------------------------                                     */
/* This program is licensed under the Apache License 2.0. You may obtain a   */
/* copy of the License at http://www.apache.org/licenses/LICENSE-2.0         */
/* It is a permissive license whose main conditions require preservation of  */
/* copyright and license notices. Contributors provide an express grant of   */
/* patent rights. Licensed works, modifications, and larger works may be     */
/* distributed under different terms and without source code. This           */
/* program is provided for tutorial purposes only. A complete handling of    */
/* error conditions has not been shown or attempted, and this program has    */
/* not been submitted to formal IBM testing. This program is distributed on  */
/* an 'AS IS' basis without any warranties either expressed or implied.      */
/*                                                                           */
/* Copyright IBM Corporation  2022                                           */
/*---------------------------------------------------------------------------*/
/* HISTORY:                                                                  */
/* 2022.02.03  T.Luther  Initial release                                     */
/*****************************************************************************/

/*---------------------------------------------------------------------------*/
/* Set default program parameters                                            */
/*---------------------------------------------------------------------------*/
/* Default CSM server to be used */
g.server = "csmservername"
/* Default executable CSMCLI & args */
g.cliex = "csmcli.bat"
g.cliex = "csmcli.sh"
/* Default CLI command */
g.clicmd = "-help csmcli"
/* CLI executable RC */
g.clirc  = 0
/* CLI Wrapper RC */
g.prgrc  = 0
/* CLI Wrapper Error Message */
g.errmsg = ""
/* Set g.dbg for additional output */
g.dbg    = 0   /* >0 print more output of procedures  */
/* Separator line for output formatting */
g.line   = left("-",79,"-")

/*---------------------------------------------------------------------------*/
/* Set environment for CSMCLI calls                                          */
/* Note: The program does not include CSMCLI username or password. It relies */
/* that the CSMCLI authentication properties file is setup in the CSM-CLI    */
/* subfolder of the specified HOME folder:                                   */
/*   <HOME>/csm-cli/csmcli-auth.properties                                   */
/* Optionally the username and password parameters can be passed as program  */
/* arguments, but this is not recommended for security reasons.              */
/*---------------------------------------------------------------------------*/
/* # of entries in env. */
env.0 = 2
/* Home for CSMCLI auth properties file */
env.1 = "HOME=/u/username"
/* Path to csmcli executable and OS binaries */
env.2 = "PATH=/bin:/opt/IBM/CSM/CLI/"


/*---------------------------------------------------------------------------*/
/* Main program                                                              */
/*---------------------------------------------------------------------------*/
parse arg args
runtime = time('E')

/* Read program arguments */
g.prgrc = PARSEARGS(args)
if g.prgrc <> 0 then
  call FINISH

/* Get Operating System and print used parameters */
if g.dbg >= 1 then do
  parse upper source g.osfull .
  say g.line
  say LOGD("Run command:" g.cliex)
  say LOGD("CSM server :" g.server)
  say LOGD("Local O/S  :" g.osfull)
  say LOGD("Debug Level:" g.dbg)
end

/* Verify and Prepare System environment */
g.prgrc = PREPAREENV()
if g.prgrc <> 0 then do
  call FINISH
end

/* Run the command */
g.prgrc = CLIWRAPPER(g.cliex)
call FINISH
exit

/*---------------------------------------------------------------------------*/
/* Subroutine FINISH                                                         */
/*                                                                           */
/* Read execution arguments and update program settings                      */
/* Return 0 if successfull, 16 on parameter error                            */
/*---------------------------------------------------------------------------*/
FINISH:
  if g.dbg >= 1 then do
    say g.line
    say LOGD("CSMCLI  RC:" g.clirc)
    say LOGD("Program RC:" g.prgrc)
    say LOGD("Error Msg :" g.errmsg)
    say LOGD("Runtime   :" GETRUNTIME(runtime))
    say g.line
  end
exit g.prgrc

/*---------------------------------------------------------------------------*/
/* Procedure PARSEARGS                                                       */
/*                                                                           */
/* Read execution arguments and update program settings                      */
/* Return 0 if successfull, 16 on parameter error                            */
/*---------------------------------------------------------------------------*/
PARSEARGS: procedure expose g.
  parse arg args
  errorrc = 16
  argstring = ''
  cmdstring = ''
  prgstring = ''
  scrused = 0
  lineon = g.dbg
  if lineon then
    say g.line
  do while args <> ''
    /* ensure to get full parm value including space */
    parse var args cmd '-' parm val ' -' args
    /* add dash back to parsed parameter and remaining parms */
    if args <> '' then
      args = '-'args
    if parm <> '' then
      parm = '-'parm
    /* strip any blanks from value */
    val = strip(val)
    if g.dbg >= 2 then
      say LOGD('PARSING: CMD:'cmd ' PARM:'parm ' VAL:'val ' ARGS:'args)
    if strip(cmd) <> '' then do
      /* Command starts */
      cmdstring = strip(cmd||parm val args)
      leave
    end
    if words(val) > 1 then do
      args = subword(val,2) args
      val = word(val,1)
    end
    /* Check parms and values and update globals */
    if parm = '-server' then do
      if val = '' then do
        g.errmsg = "Usage error: Missing value for -server"
        say LOGI(g.errmsg)
        return errorrc
      end
      g.server = val
      argstring = strip(argstring parm val)
    end
    else if parm = '-debug' then do
      if datatype(val,'W') = 0 then do
        g.dbg = 1  /* Default level if not provided */
        if val <> '' then do
          /* assume this is a command if no value and reparse */
          args = val args
        end
      end
      else
        g.dbg = val
      prgstring = '-debug' g.dbg
      if g.dbg >= 1 & lineon = 0 then
        say g.line
    end
    else do
      if parm = '-script' | parm = '-overview' then scrused = 1
      else if left(parm,2) = '-h' | parm = '-?' then scrused = 1
      argstring = strip(argstring parm val)
    end
  end
  /* Debug parsed parameters */
  if g.dbg >= 1 then do
    say LOGD('Parsed executions arguments:')
    say LOGD('PRG ARGS:' prgstring)
    say LOGD('CLI ARGS:' argstring)
    say LOGD('CLI CMD :' cmdstring)
  end
  /* Add default server if not specified */
  if wordpos('-server',argstring) = 0 & g.server <> '' then
    argstring = strip('-server' g.server argstring)
  g.cliex = g.cliex argstring
  /* Add default command if nothing specified */
  if cmdstring = '' then
    cmdstring = strip(g.clicmd)
  /* Abort if interactive mode used */
  if cmdstring = '' & scrused = 0 then do
    g.errmsg = "Usage error: No interactive console support by CSMCLI Wrapper"
    say LOGI(g.errmsg)
    return errorrc
  end
  g.cliex = g.cliex cmdstring
return 0

/*---------------------------------------------------------------------------*/
/* Procedure CLIWRAPPER                                                      */
/*                                                                           */
/* Call CSMCLI with specified cmd and verify RC & output streams.            */
/* Any CSMCLI framework RC <> 0 will be passed back with more error details  */
/* It means the command could not be sent to the server.                     */
/* If the output streams contain a CSMCLI Error message, the full message    */
/* line will be returned.                                                    */
/* 0 will be returned if the command was executed without Error message.     */
/* Eg: call CLI(command)                                                     */
/*     command: full single shot csmcli string including executable          */
/* Return codes:                                                             */
/* 0 : The command was executed successfully and Message Code is Info type   */
/* 4 : The command was executed, but Message code is Warning type            */
/* 8 : The command was executed, but resulted in an Error message            */
/* 12: The command could not be executed on the CSM server for any reason    */
/* 16: System environment for script cannot be established or missing parms  */
/* An error Message describing the problem is set in global stem, likewise   */
/* the CLI executable return code and overall wrapper return code            */
/*---------------------------------------------------------------------------*/
CLIWRAPPER: procedure expose g. env.
  parse arg mycommand
  if g.dbg >= 1 then do
    say g.line
    say LOGD("CLICMD:" mycommand)
  end
  if g.os = "TSO" then do
    g.clirc = bpxwunix(mycommand,,out.,err.,env.)
  end
  else if g.os = "WIN" then do
    address SYSTEM mycommand WITH OUTPUT STEM out. ERROR STEM err.
    g.clirc = RC
  end
  else do
    g.prgrc = 16
    g.errmsg = "ERROR: Unknown O/S to run CSMCLI executable"
    say LOGI(g.errmsg)
    return g.prgrc
  end

  if g.clirc <> 0 then do
    /* CSMCLI returns 0 if command was send to server */
    g.errmsg = "CSMCLI RC" g.clirc":"
    /* Add error info line from error or output stream */
    if err.0 > 0 then do
      /* Extract last line as error information */
      x = err.0
      g.errmsg = g.errmsg strip(err.x)
    end
    else if out.0 > 0 then do
      /* Extract last line as error information */
      x = out.0
      g.errmsg = g.errmsg strip(out.x)
    end
    /* Wrap any syntax or connection errors with RC 12 */
    g.prgrc = 12
  end

  /* Print all output lines */
  numlines = out.0
  tail = max(1,numlines-9)      /* offset for last 10 lines */
  tail = 1                      /* parse all lines          */
  founderr = 0                  /* flag if error was found  */
  do i=1 to numlines
    if g.dbg >= 1 then
      /* Use timestamp prefix for debug mode */
      say LOGD("CLIOUT:" out.i)
    else
      say out.i
    /* parse last xx lines for last message code if cmd was executed */
    if g.clirc = 0 & i >= tail & founderr = 0 then do
      /* Catch last warning message as stop at first error message */
      if pos("IWN",out.i) > 0 then do
        outline = out.i
        do while outline <> ""
          parse var outline nextword outline
          if left(nextword,3) = "IWN" then do
            if right(nextword,1) = "E" then do
              g.errmsg = strip(out.i)   /* Save full line with msg */
              if g.dbg >=1 then say LOGD("Found Error Msg:" g.errmsg)
              g.prgrc = 8
              founderr = 1
              leave
            end
            else if right(nextword,1) = "W" then do
              g.errmsg = strip(out.i)   /* Save full line with msg */
              if g.dbg >=1 then say LOGD("Found Warning Msg:" g.errmsg)
              g.prgrc = 4
              leave
            end
          end
        end
      end
    end
  end

  numlines = err.0
  /* Set min RC if something in error stream */
  if numlines > 0 then do
    g.prgrc = max(g.prgrc,8)
    /* Preset error message with first error line */
    if g.errmsg = "" then
      g.errmsg = err.1
  end
  /* Print all error lines */
  do i=1 to numlines
    if g.dbg >= 1 then
      /* Use timestamp prefix for debug mode */
      say LOGD("CLIERR:" err.i)
    else
      say err.i
    /* Catch Error message code in any line and return last code  */
    if pos("IWN",err.i) > 0 | pos("CMM",err.i) > 0 then do
      errline = err.i
      do while errline <> ""
        parse var errline nextword errline
        prefix = left(nextword,3)
        if prefix = "IWN" | prefix = "CMM" then do
          g.errmsg = strip(err.i)   /* Save full line with msg */
          if g.dbg >=1 then
            say LOGD("Found Error Msg:" g.errmsg)
          if prefix = "CMM" then
            g.prgrc = max(g.prgrc,12)
          leave
        end
      end
    end
  end

  if g.dbg >= 1 then
    say LOGD("CLIRC :" g.clirc)
return g.prgrc

/*---------------------------------------------------------------------------*/
/* Procedure PREPAREENV                                                      */
/*                                                                           */
/* Prepare system environment for program execution.                         */
/* It verifies whether the platform is supported by the program and if so    */
/* it prepares the environment for execution.                                */
/* Return codes:                                                             */
/* 0 : Preparation completed successfully                                    */
/* 16: Some environment setup error occured                                  */
/*---------------------------------------------------------------------------*/
PREPAREENV: procedure expose g. env.
  /* Get Operating System */
  parse upper source g.osfull .
  g.os = left(g.osfull,3)
  errorrc = 16
  if g.os = "TSO" then do
    /* Verify if USS syscalls are possible */
    address tso
    if syscalls('ON') > 3 then do
      g.errmsg = "ERROR: Unable to establish the USS SYSCALL environment"
      say LOGI(g.errmsg)
      return errorrc
    end
    if g.dbg >= 2 then do
      if bpxwunix('export',,out.,err.,env.) = 0 then do
        say g.line
        say LOGD("Following environment variables will be used for USS" ,
            "System Calls:")
        do i=1 to out.0
          say LOGD(out.i)
        end
      end
    end
  end
  else if g.os = "WIN" then do
    /* initialize environment variables for CSMCLI */
    if g.dbg >= 2 then do
      say g.line
      say LOGD("Following environment variables have been defined for" ,
          "System Calls on" g.osfull)
    end
    do i=1 to env.0
      parse var env.i envname "=" envvalue
      if envname = "PATH" then do
        /* extend default system path for CSMCLI */
        envvalue = value(envname,,'ENVIRONMENT') || ";" || envvalue
      end
      /* set environment variable for rexx execution*/
      call value envname, envvalue, 'ENVIRONMENT'
      if g.dbg >= 2 then do
        say LOGD(envname"="||value(envname,,'ENVIRONMENT'))
      end
    end
  end
  else do
    /* OS not supported */
    g.errmsg = "ERROR: Unsupported Operating System found:" g.osfull
    say LOGI(g.errmsg)
    return errorrc
  end
return 0

/*---------------------------------------------------------------------------*/
/* Procedure LOGI                                                            */
/*                                                                           */
/* Create common prefix for messages                                         */
/* Eg: LOGI(message)                                                         */
/*     message: String to be formatted with prefix                           */
/*---------------------------------------------------------------------------*/
LOGI: procedure
  parse arg mymsg
  /* Add timestamp as prefix to message */
  return time()":" mymsg

/*---------------------------------------------------------------------------*/
/* Procedure LOGD                                                            */
/*                                                                           */
/* Create common prefix for DEBUG messages                                   */
/* Eg: LOGD(message)                                                         */
/*     message: String to be formatted with prefix                           */
/*---------------------------------------------------------------------------*/
LOGD: procedure
  parse arg mymsg
  /* Add timestamp and debug prefix to message */
  return time()":DEBUG:" mymsg

/*---------------------------------------------------------------------------*/
/* Procedure GETRUNTIME                                                      */
/*                                                                           */
/* Calculate runtime and format to mm:ss.s based on provided start time      */
/* Eg: call GETRUNTIME(starttime)                                            */
/*     starttime: Start time saved with time('E') to use for calculation     */
/*---------------------------------------------------------------------------*/
GETRUNTIME: procedure
  parse arg mystarttime
  if datatype(mystarttime,'N') then do
    myruntime = time('E') - mystarttime
    mymin = myruntime % 60
    mysec = right(format(myruntime // 60,,1),4,'0')
    return mymin":"mysec "(min:sec)"
  end
return "??:?? (min:sec)"

