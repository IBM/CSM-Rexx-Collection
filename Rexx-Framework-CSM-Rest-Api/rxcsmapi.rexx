/* REXX                                                                     */
/*--------------------------------------------------------------------------*/
/* ABOUT THIS PROGRAM:                                                      */
/* The z/OS Rexx framework for CSM Rest API was developed to demonstrate    */
/* the z/OS TSO Web Enablement Toolkit capabilities in a simplified manner  */
/* for utilizing the IBM Copy Services Manager Rest API interface. It       */
/* enables z System Programmers and Storage Administrators to interact with */
/* IBM Copy Services Manager from a z platform without installing the CSM   */
/* CLI for z/OS. The z/OS TSO Web Enablement Toolkit is available with z/OS */
/* 2.2 or later and provides HTTP and JSON services that are callable       */
/* through various program languages. For more information, please refer:   */
/* - https://www.ibm.com/docs/en/zos/2.2.0?topic=consider-zos-client-web-en */
/*   ablement-toolkit                                                       */
/* The Rexx framework provides functions and procedures to utilize the web  */
/* enablement toolkit services in Rexx. It re-uses Rexx examples from       */
/* following sources:                                                       */
/* - https://github.com/IBM/zOS-Client-Web-Enablement-Toolkit               */
/* - SYS1.SAMPLIB(HWTJSPRT) to print formatted JSON text                    */
/* The framework does not only provide necessary HTTP request handling and  */
/* JSON response parsing, but it also provides other additional features    */
/* that greatly simplify the z/OS web enablement toolkit usage for CSM Rest */
/* API. For a generic usage description of the CSM Rest API, please refer:  */
/* - https://www.ibm.com/docs/en/csm/6.3.1?topic=reference-csm-rest-api-doc */
/*   umentation                                                             */
/* For usage description, please refer to the README or to the document:    */
/* - zOS Rexx framework for CSM Rest API.pdf                                */
/*--------------------------------------------------------------------------*/
/* COPYRIGHT INFORMATION AND DISCLAIMER:                                    */
/* Like the z/OS Web Enablement toolkit is licensed under the Apache        */
/* License 2.0, this Rexx framework is licensed under the same conditions.  */
/* You may obtain a copy of the License at                                  */
/* http://www.apache.org/licenses/LICENSE-2.0                               */
/* It is a permissive license whose main conditions require preservation of */
/* copyright and license notices. Contributors provide an express grant of  */
/* patent rights. Licensed works, modifications, and larger works may be    */
/* distributed under different terms and without source code.  This         */
/* framework is provided for tutorial purposes only. A complete handling of */
/* error conditions has not been shown or attempted, and this program has   */
/* not been submitted to formal IBM testing. This program is distributed on */
/* an 'as is' basis without any warranties either expressed or implied.     */
/*                                                                          */
/* Copyright IBM Corporation  2022                                          */
/*--------------------------------------------------------------------------*/
/* HISTORY:                                                                 */
/* 2021.12.12  T.Luther  Initial release                                    */
/* 2021.12.27  T.Luther  Added CSM_RunHaCmd & CheckCsmCmdResp functions     */
/*                       Added CSM_GetSessCpSets function, fixed -u parsing */
/* 2022.01.11  T.Luther  Fixed default parms for CSM_GetSessCpSets          */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* Main routine                                                             */
/*--------------------------------------------------------------------------*/
parse arg args
/* Initialize global variables with default settings */
call InitializeVars
/* parse execution arguments and update global settings for execution */
rc = ParseArgs(args)
if rc <> 0 then
  call usage g.execname, rc
/* Initialize Web Enablement Toolkit REXX constants */
if HTTP_getToolkitConstants() <> 0 then
  cleanup('** z/OS Web enablement Toolkit environment error **')

/*--------------------------------------------------------------------------*/
/* Execute specified request or function if execution parameters specified  */
/*--------------------------------------------------------------------------*/
if args <> '' then
do
  if g.reqFunc = '' then
  do
    /* Execute single request and display formatted response */
    if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
    do
      if g.resBody <> "" then
        say g.resBody
      cleanup('** Requst failed **')
    end
    /* Parse and display the request output if JSON */
    if g.resType = "JSON" then
    do
      if JSON_print(g.resBody, g.pFilter) <> 0 then
        cleanup('** Error while printing JSON data **')
    end
    g.progRc = 0
    cleanup('')
  end
  else
  do
    /* Execute internal function */
    /* ensure correct syntax for function call */
    if pos('(',word(g.reqFunc,1)) = 0 then
    do
      if words(g.reqFunc) > 1 then
      do
        if left(word(g.reqFunc,2),1) <> '(' then
          g.reqFunc = word(g.reqFunc,1)'('subword(g.reqFunc,2)
        else
          g.reqFunc = word(g.reqFunc,1)||subword(g.reqFunc,2)
      end
      else
        g.reqFunc = word(g.reqFunc,1)'('
    end
    if right(g.reqFunc,1) <> ')' then
      g.reqFunc = g.reqFunc')'
    /* trap syntax error when interpreting function calls */
    signal on syntax
    signal on error
    if g.showInfo | g.verbose then
      say 'Calling function:' g.reqFunc
    interpret 'x =' g.reqFunc
    g.progRc = x
    cleanup('')
  end
end

/*--------------------------------------------------------------------------*/
/* Usage examples for main if no arguments are used                         */
/* Send requests and display formatted response                             */
/* Or create and download a csm server backup file                          */
/* This part of the main procedure is executed when no parameters provided  */
/* Modify and expand the required execution actions as required             */
/*--------------------------------------------------------------------------*/

/* Set display variables for execution */
g.showInfo = 0
g.verbose  = 0

/* Set server connection variables and file names */
g.cUri    = 'https://csmserver'
g.cPort   = '9559'
g.cKeyDb  = '/u/username/csmcerts.p12'
g.cDbStash= '/u/username/csmcerts.sth'
g.cCertLab = 'certLabel'

/* Set table print defaults for internal CSM functions */
g.tHeader = 1     /* Display output header 1 or 0 */
g.tFormat = 1     /* Display alligned table columns 1 or 0 */
g.tDelim  = '|'   /* Delim char for field separation */

/* Indicate Program start  */
if g.showInfo then
do
  say
  say '*************************************'
  say '** Rexx framework for CSM Rest API **'
  say '*************************************'
end

/*--------------------------------------------------------------------------*/
/* Examples to use internal functions in main                               */
/*--------------------------------------------------------------------------*/

/*** Print Session overview *************************************************/
/*
if CSM_SessOverview(g.tHeader,g.tFormat,g.tDelim) <> 0 then
  /* Cleanup and exit programm on printing error */
  cleanup('** Error while printing session overview **')
*/

/*** Print Storage device overview ******************************************/
/*
if CSM_SysOverview(g.tHeader,g.tFormat,g.tDelim) <> 0 then
  /* Cleanup and exit programm on printing error */
  cleanup('** Error while printing storage device overview **')
*/

/*** Print available backups for a session **********************************/
/*
sessname = 'MySession'
if CSM_GetSessBackups(sessname,g.tHeader,g.tFormat,g.tDelim) <> 0 then
  /* Cleanup and exit programm on printing error */
  cleanup('** Error while printing available session backups **')
*/

/*** Get available commands for a session ***********************************/
/*
sessname = 'MySession'
if CSM_GetSessCmd(sessname,g.tHeader,g.tFormat,g.tDelim) <> 0 then
  /* Cleanup and exit programm on printing error */
  cleanup('** Error while printing available session commands **')
*/

/*** Run a command against a session ****************************************/
/*
sessname = 'MySession'
command  = 'Start H1->H2'
g.progRc = CSM_RunSessCmd(sessname,command)
if g.progRc <> 0 then
do
  if g.progRc < 0 then
    cleanup('** Aborted: Unexpected error while issuing command **')
  else if g.progRc > 12 then
    cleanup('** Aborted: Command completion status unknown **')
  else if g.progRc > 4 then
    cleanup('** Command completed with an Error **')
  else if g.progRc > 0 then
    cleanup('** Command completed with a Warning **')
  else
    nop
end
*/


/*--------------------------------------------------------------------------*/
/* Examples to issue a request and extract specific data via JSON parser    */
/*--------------------------------------------------------------------------*/
/* Some CSM API request path examples */
/*
g.reqPath = '/CSM/web/storagedevices?type=ds8000'
g.reqPath = '/CSM/web/sessions/<sessname>/availablecommands'
g.reqPath = '/CSM/web/sessions/scheduledtasks'
g.reqPath = '/CSM/web/sessions'
g.reqPath = '/CSM/web/sessions/short'
g.reqPath = '/CSM/web/sessions/<sessname>'
g.reqPath = '/CSM/web/system/backupserver/download'
*/

/*** Example to query the CSM HA server information and find the Port *******/
/*
g.reqType = 'GET'
g.reqPath = '/CSM/web/system/ha'
g.reqBody = ''
g.OutFile = ''
/* Use HTTP_sendRequest wrapper to initialize and send a request */
if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
do
  /* Cleanup and exit programm on request error */
  cleanup('** Request failed **')
end
/* First parse the response to initialize the parser handle */
if JSON_parse(g.resBody) <> 0 then
  /* Cleanup and exit programm on parsing error */
  cleanup('** Error while parsing returned data **')
/* Find specific entry in the parser handle starting from root object */
say g.cUri": Local HA port:" JSON_findValue(0,'localhaport',HWTJ_NUMBER_TYPE)
*/

/*** Example to query CSM HA server information & display formatted JSON ****/

g.reqType = 'GET'
g.reqPath = '/CSM/web/system/ha'
g.reqBody = ''
g.OutFile = ''
g.pFilter = ''
/* Use HTTP_sendRequest wrapper to initialize and send a request */
if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
do
  /* Cleanup and exit programm on request error */
  cleanup('** Request failed **')
end
if JSON_print(g.resBody, g.pFilter) <> 0 then
  /* Cleanup and exit programm on parsing or print error */
  cleanup('** Error while printing JSON data **')


/*** Example to create and download a backup zip file of the CSM server *****/
/*** Note: Stream data maximum size is 16 MB (Rexx variable limit) **********/
/*
g.reqType = 'GET'
g.reqPath = '/CSM/web/system/backupserver/download'
g.reqBody = ''
g.OutFile = '/u/username/csmbackup.zip'   /* Must be USS file */
/* Use wrapper to send request with disabled response translation */
/* A2E translation of response body would corrupt binary stream data */
if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile,0) <> 0 then
do
  cleanup('** Request failed **')
end
*/


/* Release all instances and exit */
g.progRc = 0
cleanup('')
exit

/* Trapped Syntax error (for malformed internal function calls) */
syntax: error:
  cleanup('** REXX problem in' g.execname 'line' sigl':' ,
          errortext(rc)', Sourceline' sigl':'sourceline(sigl))


/*--------------------------------------------------------------------------*/
/* Function: InitalizeVars                                                  */
/*--------------------------------------------------------------------------*/
/* Initialize global vars used throughout the program                       */
/*--------------------------------------------------------------------------*/
InitializeVars:
  g.        = ''  /* Initialize empty global stem for all settings */
  g.progRc  = -1  /* Indicate severe error upon abort */
  g.showInfo= 0   /* 1 for additional runtime information */
  g.verbose = 0   /* 1 for detailed output/debugging */
  /* Get runtime environment variables of rexx */
  parse source g.host . g.execname . g.rexxdsn . g.environ g.adspace .

  /* Set default File or DSN definitions for rexx */
  g.Pref    = '/u/username/csmapi/' /* Common DSN/Path prefix for following */
  /* Member for ISPF credential prompt panel */
  g.IPanDsn = g.Pref'(ISPFPASS)'  /* This must be a member */
  g.IPanDD  = 'ISPFPASS'     /* DD Name for ISPF panel member to query Cred */
  /* DSN/file to save encrypted credentials */
  g.AuthFile= g.Pref'credent.txt'
  g.authDD  = 'CREDFILE'     /* DD Name for credentials */
  /* DSN/file to save encryption private key */
  g.EncrFile= g.Pref'credent.key'
  g.encrDD  = 'CREDKEY'      /* DD Name for private key */
  /* DSN/file for HTTP connection verbose trace, default = STDOUT */
  g.TraceFile = ''
  g.traceDD = 'APITRACE'     /* DD Name for trace */
  /* USS output file to save http response data */
  g.OutFile = ''
  g.outDD   = 'APIOUTFI'     /* DD Name for output file */

  /* Initialize connection related variables for CSM server  */
  g.cHandle  = ''     /* Pointer to the connection handle */
  g.cUri     = ''     /* CSM Server URL  */
  g.cPort    = ''     /* CSM Server Port */
  g.cKeyRing = ''     /* SAF keyring in form: userid/keyring */
                      /* or PKCS11 token:     *TOKEN* /token_name */
  g.cKeyDb   = ''     /* PKCS12 Keystore USS file with SSL cert */
  g.cDbStash = ''     /* PKCS12 V1 Stash with PW for keystore */
  g.cCertLab = ''     /* Certificate label */
  /* Initialize framework related settings (do not modify) */
  g.rPriKey  = ''     /* Private key for encoding of saved credentials */
  g.rUsername= ''     /* CSM server user name, read from cred file */
  g.rPassword= ''     /* CSM server password, read from cred file */
  g.rToken   = ''     /* CSM server token, read from file or request new */
  g.rTokenSet= 0      /* Flag to indicate whether token added to header */
  /* Initialize request-related variables */
  g.reqType  = ''     /* Initial request method */
  g.reqPath  = ''     /* Initial service path */
  g.reqBody  = ''     /* Initial request body (data and parms) */
  g.reqHeader. = ''   /* Stem variable containing header parameters */
  g.reqFunc  = ''     /* If defined it will be interpreted as internal   */
                      /* function call instead of issuing single request */
  /* Define default headers for CSM requests */
  g.reqHeader.0 = 2   /* Adjust to the number of specified header parms */
  g.reqHeader.1 = 'Accept-Language: en-US'  /* Responses in English */
  g.reqHeader.2 = 'Content-Type: application/x-www-form-urlencoded'
  /* Initialize response-related variables, filled after request done  */
  g.resCode  = ''     /* Response return code */
  g.resReason= ''     /* Response reason code */
  g.resHeaders. = ''  /* Stem holding the response header information */
  g.resBody  = ''     /* Response data returned in body */
  g.resA2E   = ''     /* Flag to indicate setting of A2E resp translation */
  g.resType  = ''     /* Content type of data in body */
  g.resSize  = ''     /* Content size in Bytes */
  g.resData. = ''     /* Stem holding the JSON data in lines after parse */
  g.resData.0= 0      /* Number of fornatted JSON data lines */
  /* Initialize parser related variables  */
  g.pHandle  = ''     /* Pointer to parser handle */
  g.pDisp    = 0      /* 1 if parsed Input text should be displayed */
  g.pFilter  = ''     /* Initial filter setting for responses */
  g.pOut.    = ''     /* Global stem to use for formatted table output */
  /* Initialize Table print related variables for CSM functions */
  g.tHeader  = 1      /* Default setting for printing table header 0/1 */
  g.tFormat  = 1      /* Default setting for alligned table columns 0/1 */
  g.tDelim   = '|'    /* Default Delim char for table fields */
  g.tTimeOff = ''     /* Define hh:mm to convert Unix timestamps with offset */
                      /* for local TZ. Invalid offset disables conversion.   */
  if g.tTimeOff = '' then
    g.tTimeOff= TimeOffset() /* Determine local time offset automatically */
  /* Initialize JSON print related variables  */
  g.pNameWidth=16     /* define minimum name width to print JSON objects */
  g.pCols    = 2      /* define number of columns to indent nested entries */
  g.pIndent  = 0      /* marker for numer of indents in use */
  g.pQchar   = '"'    /* Quote char */
  g.pCchar   = ','    /* Comma char */
  g.pArr     = 0      /* Marker if printing array */
  g.pEsc     = 0      /* 1 will remove escape char as defined below '{}[]' */
  /* Char set for JSON print brackets and braces */
  g.pOBrak   = '['    /* Char for open bracket starting of array */
  g.pCBrak   = ']'    /* Char for closed bracket ending of array */
  g.pOBrac   = '{'    /* Char for open braces starting of object */
  g.pCBrac   = '}'    /* Char for closed braces ending of object */
  /* Use Adjusted display char set for different code pages if required */
  /*
  g.pOBrak   = ''
  g.pCBrak   = ''
  g.pOBrac   = ''
  g.pCBrac   = ''
  */
return

/*--------------------------------------------------------------------------*/
/* Procedure: ParseArgs                                                     */
/*--------------------------------------------------------------------------*/
/* Read execution arguments and update program settings                     */
/* Return 0 if successfull, -1 on parameter error                           */
/*--------------------------------------------------------------------------*/
ParseArgs: procedure expose g.
  parse arg args
  do while args <> ''
    /* ensure to get full parm value including space */
    parse var args '-' parm val ' -' args
    /* add dash back to parsed parameter and remaining parms */
    if args <> '' then
      args = '-'args
    if parm <> '' then
      parm = '-'parm
    /* strip any blanks from value */
    val = strip(val)
    /* strip any quotes from value if no function call */
    if parm <> '-u' then
      val = strip(strip(val,,"'"),,'"')
    /* Check parms and values and update globals */
    if parm = '-h' then do
      parse var val prot '://' host ':' port
      if left(prot,4) <> 'http' then
        return fatalError('Usage error: Invalid protocol in host parameter:',
               prot)
      if host = '' then
        return fatalError('Usage error: Missing server in host parameter')
      if port = '' then
        return fatalError('Usage error: Missing Port in host parameter')
      if datatype(port,'W') = 0 then
        return fatalError('Usage error: Invalid Port in host parameter:',
               port)
      /* Set connection URI and port */
      g.cUri = prot'://'host
      g.cPort = port
    end
    else if parm = '-k' then do
      if val = '' then
        return fatalError('Usage error: Missing filename or keyring '|| ,
               'in key parameter')
      /* Identify pattern for keyfile or keyring */
      parse var val pref '/' suf '/' more
      lp = length(pref)
      /* Set PKS12 key db if no matching pattern for */
      /* PKCS 11 token: *TOKEN* /token_name (without blank) */
      /* Keyring      : userid/keyring */
      if more <> '' | suf = '' | lp < 3 | lp > 8 then
        g.cKeyDb = val
      else
        g.cKeyRing = val
    end
    else if parm = '-s' then do
      if val = '' then
        return fatalError('Usage error: Missing filename in Stash parameter')
      /* Set PKS12 stash file */
      g.cDbStash = val
    end
    else if parm = '-l' then do
      if val = '' then
        return fatalError('Usage error: Missing name in label parameter')
      /* Set certificate label name */
      g.cCertLab = val
    end
    else if parm = '-u' then do
      if val = '' then
        return fatalError('Usage error: Missing function to use for parameter')
      /* Allow only specific functions */
      functions = 'CSM_SessOverview(hdr,fmt,delim,sort)' ,
                  'CSM_SysOverview(hdr,fmt,delim,sort)' ,
                  'CSM_PathOverview(hdr,fmt,delim,sort)' ,
                  'CSM_TaskOverview(hdr,fmt,delim,sort)' ,
                  'CSM_GetSysPaths(sys,hdr,fmt,delim,sort)' ,
                  'CSM_GetSessCpSets(sess,cols,hdr,fmt,delim,sort)' ,
                  'CSM_GetSessBackups(sess,hdr,fmt,delim,sort)' ,
                  'CSM_GetSessCmd(sess,hdr,fmt,delim,sort)' ,
                  'CSM_RunSessCmd(sess,cmd,parm)' ,
                  'CSM_RunHaCmd(cmd,remoteserver:port,user,pwd)' ,
                  'CSM_RunTaskCmd(taskid,cmd,datetime,sync)' ,
                  'CSM_ShowTask(task,hdr,fmt,delim)'
      /* Extract function name from parm and compare without case */
      parse var val fname '(' fparms
      if pos(translate(word(fname,1))'(',translate(functions)) = 0 then
      do
        say 'Need valid function:'
        do i = 1 to words(functions)
          say '  'word(functions,i)
        end
        return fatalError('Usage error: Invalid function for Use parameter:' ,
                          val)
      end
      /* Set internal function call */
      /* Compose correct syntax for function interpretion */
      fparms = strip(subword(fname,2) fparms)
      fparms = strip(fparms,'T',')')
      g.reqFunc = word(fname,1)'('
      do while fparms <> ''
        parse var fparms fp ',' fparms
        /* check if quoted parm */
        if pos('"',fp) > 0 then
        do
          /* get remainder of parm */
          fparms = fp','fparms
          parse var fparms '"' fp '"' ',' fparms
        end
        if pos("'",fp) > 0 then
        do
          /* get remainder of parm */
          fparms = fp','fparms
          parse var fparms "'" fp "'" ',' fparms
        end
        else
          fp = strip(fp)
        /* Ensure each non numeric parameter is quoted */
        if fp <> '' & datatype(fp,'N') = 0 then
          fp = "'"fp"'"
        g.reqFunc = g.reqFunc||fp','
      end
      /* Remove last , and close function call */
      if right(g.reqFunc,1) = ',' then
        g.reqFunc = left(g.reqFunc,length(g.reqFunc)-1)
      g.reqFunc = g.reqFunc')'
    end
    else if parm = '-r' then do
      if val = '' then
        return fatalError('Usage error: Missing type in request parameter')
      upper val
      if wordpos(val,'GET PUT POST DELETE HEAD') = 0 then
        return fatalError('Usage error: Invalid type in request parameter:',
        val)
      /* Set valid request type */
      g.reqType = val
    end
    else if parm = '-p' then do
      if val = '' then
        return fatalError('Usage error: Missing service name in path parameter')
      /* Set full request path */
      g.reqPath = '/'strip(val,,'/')
    end
    else if parm = '-d' then do
      if val = '' then
        return fatalError('Usage error: Missing input in data parameter')
      /* Set data for request body */
      g.reqBody = val
    end
    else if parm = '-c' then do
      if val = '' then
        return fatalError('Usage error: Missing filename in credentials' ,
               'parameter')
      /* Set credentials file */
      g.AuthFile = val
    end
    else if parm = '-e' then do
      if val = '' then
        return fatalError('Usage error: Missing filename in encryption key' ,
               'parameter')
      /* Set encryption key file */
      g.EncrFile = val
    end
    else if parm = '-i' then do
      /* No value expected, add next parm back to args */
      if left(val,1) = '-' then
        args = val args
      /* Enable show Info */
      g.showInfo = 1
    end
    else if parm = '-v' then do
      /* No value expected, add next parm back to args */
      if left(val,1) = '-' then
        args = val args
      /* Enable verbose */
      g.verbose = 1
    end
    else if parm = '-t' then do
      if val = '' then
        return fatalError('Usage error: Missing filename in trace parameter')
      g.TraceFile = val
    end
    else if parm = '-o' then do
      if val = '' then
        return fatalError('Usage error: Missing filename in output parameter')
      if pos('/',val) = 0 then
        return fatalError('Usage error: Output file must contain USS path')
      g.OutFile = val
    end
    else if parm = '-f' then do
      if val = '' then
        return fatalError('Usage error: Missing fieldname in filter parameter')
      /* Compose quoted filter fields */
      g.pFilter = ''
      do while val <> ''
        parse var val field ',' val
        if strip(field) <> '' then
          g.pFilter = g.pFilter'"'strip(strip(field,,"'"),,'"')'",'
      end
      g.pFilter = strip(g.pFilter,,',')
    end
    else do
      return fatalError('Usage error: Unknown parameter:' parm)
    end
  end
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: Usage                                                         */
/*--------------------------------------------------------------------------*/
/* Print Usage with execution parameters and exit with cleanup and RC       */
/*--------------------------------------------------------------------------*/
Usage: procedure expose g.
  parse arg prg, retcode
  say 'Program Execution Parameters:' prg
  say '---------------------------------------------------------------------'
  say '-h: Host URI with protocol, host, port to be used for the connection'
  say '-k: Key database file or keyring with certificate for HTTPS connections'
  say '-s: Stash file to access the key database file'
  say '-l: Label of certificate in PKCS12 key database'
  say '-u: Use specified internal CSM function (will ignore -r -p -d -f)'
  say '-r: Request type: GET, PUT, POST, DELETE, HEAD'
  say '-p: Full URI path to the requested service'
  say '-d: Data to send in request body, such as input parameter'
  say '-c: USS file or DSN(Mbr) to save CSM server credentials'
  say '-e: USS file or DSN(Mbr) with encryption key for server credentials'
  say '-i: Enable informative output (Default is disabled)'
  say '-v: Enable verbose output (Default is disabled)'
  say '-t: Optional Trace File for verbose connection output (Default Stdout)'
  say '-f: Filter for JSON root object entries to be displayed'
  say '-o: USS Output file to save response data (Required for Stream data)'
  say
  say 'Example:'
  say prg '-h "https://hostname:port" -k "/u/username/keystore.p12"' ,
      '-s "/u/username/keystore.sth" -l "certlabel"',
      '-c "/u/username/cred.txt" -e "/u/username/credkey.txt" -r "POST"',
      '-p "/CSM/web/sessions/<name>/backups/H1/<backupid>"' ,
      '-d "cmd=Recover%20Backup" -i -f "msgTranslated","timestamp"'
  g.progRc = retcode
  cleanup()
return


/*--------------------------------------------------------------------------*/
/*                    CSM Rest API related functions                        */
/*--------------------------------------------------------------------------*/
/* These CSM_xxx functions are specific CSM Rest API calls to               */
/* demonstrate use of the API framework functions for processing http       */
/* requests and parsing the response for a formatted table display.         */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_SessOverview                                              */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of a CSM session overview    */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_SessOverview: procedure expose g. (HWT_CONSTANTS)
  parse arg hdr, fmt, delim, sort
  /* Define default sort */
  if sort = '' then
    sort = '6d,4d,1'  /* Sort most critical sess states first */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Short session overview */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/sessions/short'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say 'Querying CSM sessions from' g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing session objects */
  /* initialize global output stem for formatted Session summary output */
  call InitTable 'SessName, #CpSets, ActHost, Status, State, HasError,'||,
                 'Recoverable, HS-Status, SessType'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        o = g.pout.0 + 1
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* process each entry in the object */
        do oix = 0 by 1 while oix < onum
          /* Get object entry token and name */
          parse value JSON_getObjEntry(etok,oix) with oetok 5 oename
          /* Extract desired fields for custom formatting */
          if oename = 'name' then
            g.pout.o.1 = JSON_getValEntry(oetok)
          else if oename = 'numcopysets' then
            g.pout.o.2 = JSON_getValEntry(oetok)
          else if oename = 'productionhost' then
            g.pout.o.3 = JSON_getValEntry(oetok)
          else if oename = 'status' then
            g.pout.o.4 = JSON_getValEntry(oetok)
          else if oename = 'state' then
            g.pout.o.5 = JSON_getValEntry(oetok)
          else if oename = 'haserror' then
            g.pout.o.6 = JSON_getBoolEntry(oetok)
          else if oename = 'recoverable' then
            g.pout.o.7 = JSON_getBoolEntry(oetok)
          else if oename = 'hyperswapstatus' then
            g.pout.o.8 = JSON_getValEntry(oetok)
          else if oename = 'rulesname' then
            g.pout.o.9 = JSON_getValEntry(oetok)
        end
        /* Update column max values */
        do j = 1 to g.pout.0.0
          g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
        end
        g.pout.0 = o
      end
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for short session query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       ' CSM session overview:' g.pout.0 'sessions',sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_SysOverview                                               */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of a CSM storage system      */
/* overview. This implements another method to process JSON entries.        */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_SysOverview: procedure expose g. (HWT_CONSTANTS)
  parse arg hdr, fmt, delim, sort
  /* Define default sort */
  if sort = '' then
    sort = '2,1'  /* Sort Type and Name ascending */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Storage Device overview */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/storagedevices'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say 'Querying CSM storage devices from' g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing storage device objects */
  /* initialize global output stem for formatted device summary output */
  call InitTable 'DevName, DevType, Vendor, #Con, Location, Serial,'||,
                 'DevID, Model'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        o = g.pout.0 + 1
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the object */
        if onum > 0 then
        do
          g.pout.o.1 = JSON_findValue(etok,'devicename',HWTJ_STRING_TYPE)
          g.pout.o.2 = JSON_findValue(etok,'systemtype',HWTJ_STRING_TYPE)
          g.pout.o.3 = JSON_findValue(etok,'manufacturer',HWTJ_STRING_TYPE)
          ae = JSON_findValue(etok,'connections',HWTJ_ARRAY_TYPE)
          if ae <> '' then
            g.pout.o.4 = JSON_getNumElem(ae)
          else
            g.pout.o.4 = 0
          g.pout.o.5 = JSON_findValue(etok,'location',HWTJ_STRING_TYPE)
          g.pout.o.6 = JSON_findValue(etok,'serial',HWTJ_STRING_TYPE)
          g.pout.o.7 = JSON_findValue(etok,'deviceid',HWTJ_STRING_TYPE)
          g.pout.o.8=JSON_findValue(etok,'machinemodelnumber',HWTJ_STRING_TYPE)
          /* Update column max values */
          do j = 1 to g.pout.0.0
            g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
          end
        end
        g.pout.0 = o
      end
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for storage device query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       ' CSM storage device overview:' g.pout.0 'devices',sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_PathOverview                                              */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of PPRC paths between        */
/* storage systems.                                                         */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_PathOverview: procedure expose g. (HWT_CONSTANTS)
  parse arg hdr, fmt, delim, sort
  /* Define default sort */
  if sort = '' then
    sort = '1,2'  /* Sort Source systems and target system ascending */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Compose command URL and body parms as required */
  g.reqType = 'GET'
  /* convert blanks to %20 in URL */
  g.reqPath = '/CSM/web/storagedevices/paths'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Getting PPRC paths for all devices ..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing path objects */
  /* initialize global output stem for PPRC paths per system pair */
  call InitTable 'SrcSystem,TgtSystem,#GoodPath,#BadPath,ErrStates'
  type = JSON_getType(0)  /* Obtain entry type of root */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** No path information found **')
    if g.verbose then
      say 'Found' anum 'elements in path array'
    /* Note: Array contains LSS pair objects per path state */
    /* initialize variables to accumulate path counts for System pairs */
    syspairs = ''
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the object */
        if onum > 0 then
        do
          stype = JSON_findValue(etok,'storagetype',HWTJ_STRING_TYPE)
          /* Skip any non PPRC path objects */
          if stype <> "ESS" then iterate
          srcsys = JSON_findValue(etok,'pathsourceid',HWTJ_STRING_TYPE)
          tgtsys = JSON_findValue(etok,'pathtargetid',HWTJ_STRING_TYPE)
          okpath = JSON_findValue(etok,'numberofgoodpaths',HWTJ_NUMBER_TYPE)
          erpath = JSON_findValue(etok,'numberoferrorpaths',HWTJ_NUMBER_TYPE)
          pstate = JSON_findValue(etok,'detailedstate',HWTJ_NUMBER_TYPE)
          /* Extract system ID without LSS */
          parse var srcsys srcsys ':' .
          parse var tgtsys tgtsys ':' .
          idx = wordpos(srcsys':'tgtsys,syspairs)
          if idx = 0 then
          do
            /* add new pair into line and lookup string */
            syspairs = syspairs srcsys':'tgtsys
            g.pout.0 = words(syspairs)
            idx = g.pout.0
            g.pout.idx.1 = srcsys
            g.pout.idx.2 = tgtsys
            g.pout.idx.3 = okpath
            g.pout.idx.4 = erpath
            if erpath > 0 then
              g.pout.idx.5 = erpath '('pstate')'
            /* Update column max values */
            do j = 1 to g.pout.0.0
              g.pout.0.j = max(g.pout.0.j,length(g.pout.idx.j))
            end
          end
          else
          do
            /* increase counts for existing pairs */
            g.pout.idx.3 = g.pout.idx.3 + okpath
            g.pout.0.3 = max(g.pout.0.3,length(g.pout.idx.3))
            g.pout.idx.4 = g.pout.idx.4 + erpath
            g.pout.0.4 = max(g.pout.0.4,length(g.pout.idx.4))
            if erpath > 0 then
            do
              sidx = wordpos('('pstate')',g.pout.idx.5)
              if sidx = 0 then
              do
                /* add new error state count */
                g.pout.idx.5 = g.pout.idx.5 erpath '('pstate')'
              end
              else
              do
                /* increase counts for existing state */
                g.pout.idx.5 = subword(g.pout.idx.5,1,sidx-2) ,
                               subword(g.pout.idx.5,sidx-1,1)+erpath ,
                               subword(g.pout.idx.5,sidx)
              end
            end
          end
        end
      end
    end aix
    /* Reformat bad path column */
    do i = 1 to g.pout.0
      str = ''
      s = words(g.pout.i.5)
      do k = 1 to s by 2
        str = str||word(g.pout.i.5,k)':'
        parse value word(g.pout.i.5,k+1) with '(' pstat ')' .
        if datatype(pstat,'W') then
          pstat = '0x'd2x(pstat,2)  /* Convert state to hex */
        /* translate hex path state */
        select
          when pstat = '0x02' then pstat = "InitFail"
          when pstat = '0x03' then pstat = "Timeout"
          when pstat = '0x04' then pstat = "NoResPri"
          when pstat = '0x05' then pstat = "NoResSec"
          when pstat = '0x06' then pstat = "SerialMism"
          when pstat = '0x07' then pstat = "SecSsidMism"
          when pstat = '0x08' then pstat = "EsconLinkOff"
          when pstat = '0x09' then pstat = "RetryEstabl"
          when pstat = '0x0A' then pstat = "ActiveHost"
          when pstat = '0x0B' then pstat = "SameCluster"
          when pstat = '0x10' then pstat = "CfgError"
          when pstat = '0x14' then pstat = "FcDown"
          when pstat = '0x15' then pstat = "FcRetryExd"
          when pstat = '0x16' then pstat = "SecAdptIncptl"
          when pstat = '0x17' then pstat = "SecAdptUnav"
          when pstat = '0x18' then pstat = "FcPriLoginExd"
          when pstat = '0x19' then pstat = "FcSecLoginExd"
          when pstat = '0x1A' then pstat = "PriAdptIncptl"
          when pstat = '0x1B' then pstat = "FcDegraded"
          when pstat = '0x1C' then pstat = "FcRemoved"
          when pstat = '0xFF' then pstat = "UnableDet"
          otherwise nop
        end
        str = str||pstat','
      end k
      g.pout.i.5 = strip(str,'T',',')
      g.pout.0.5 = max(g.pout.0.5,length(g.pout.i.5))
    end i
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for path query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       ' CSM PPRC path overview:' g.pout.0 'System Pairs',sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_TaskOverview                                              */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of CSM scheduled tasks.      */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_TaskOverview: procedure expose g. (HWT_CONSTANTS)
  parse arg hdr, fmt, delim, sort
  /* Define default sort */
  if sort = '' then
    sort = '3d,4,2'  /* Sort enabled tasks first with next run and name */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Storage Device overview */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/sessions/scheduledtasks'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say 'Querying CSM scheduled tasks from' g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing task objects */
  /* initialize global output stem for formatted device summary output */
  call InitTable '#ID, Name, State, NextRun, LastRun,'||,
                 'LastMsg, #NumMsg, SchedType, #Act, Sessions'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        o = g.pout.0 + 1
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the object */
        if onum > 0 then
        do
          g.pout.o.1 = JSON_findValue(etok,'id',HWTJ_NUMBER_TYPE)
          g.pout.o.2 = JSON_findValue(etok,'name',HWTJ_STRING_TYPE)
          /* Report State of task depending on 3 flags */
          enabled = JSON_findValue(etok,'enabled',HWTJ_BOOLEAN_TYPE)
          running = JSON_findValue(etok,'running',HWTJ_BOOLEAN_TYPE)
          penAppr = JSON_findValue(etok,'pendingApproval',HWTJ_BOOLEAN_TYPE)
          upper enabled running penAppr
          if penAppr = 'TRUE' then
            g.pout.o.3 = 'PendAppr'
          else if running = 'TRUE' then
            g.pout.o.3 = 'Running'
          else if enabled = 'TRUE' then
            g.pout.o.3 = 'Enabled'
          else
            g.pout.o.3 = 'Disabled'
          g.pout.o.4 = JSON_findValue(etok,'nextRun',HWTJ_NUMBER_TYPE)
          g.pout.o.4 = ConvUnixTime(g.pout.o.4)
          g.pout.o.5 = JSON_findValue(etok,'lastRan',HWTJ_NUMBER_TYPE)
          g.pout.o.5 = ConvUnixTime(g.pout.o.5)
          /* Messages array */
          ae = JSON_findValue(etok,'messages',HWTJ_ARRAY_TYPE)
          if ae <> '' then
          do
            /* each array entry is msg object, sorted asc by timestamp */
            maxtime = 0
            aenum = JSON_getNumElem(ae)
            /* Just pick last entry and use as last message */
            if aenum > 0 then
            do
              atok = JSON_getArrEntry(ae,aenum-1)
              atype = JSON_getType(atok)
              if atype = HWTJ_OBJECT_TYPE then
                g.pout.o.6 = JSON_findValue(atok,'msg',HWTJ_STRING_TYPE)
            end
            /* Cycle through all msg objects and find max timestamp */
            /*
            do aeix = 0 by 1 while aeix < aenum
              /* get next object */
              atok = JSON_getArrEntry(ae,aeix)
              atype = JSON_getType(atok)
              if atype = HWTJ_OBJECT_TYPE then
              do
                mtime = JSON_findValue(atok,'baseDate',HWTJ_NUMBER_TYPE)
                if datatype(mtime,'W') then
                do
                  if mtime >= maxtime then
                  do
                    /* use last msg if time stamp is the same */
                    maxtime = mtime  /* save max time and last message */
                    g.pout.o.6 = JSON_findValue(atok,'msg',HWTJ_STRING_TYPE)
                  end
                  else
                    say 'Unsorted message:' aeix + 1
                end
              end
            end
            */
            g.pout.o.7 = aenum
          end
          else
            g.pout.o.7 = 0
          /* Schedule object */
          oe = JSON_findValue(etok,'schedule',HWTJ_OBJECT_TYPE)
          if oe <> '' then
          do
            stype = JSON_findValue(oe,'type',HWTJ_STRING_TYPE)
            /* Compose schedule details in single field */
            if stype = 'NoTaskSchedule' then
              g.pout.o.8 = 'No Schedule'
            else if stype = 'WeeklyTaskSchedule' then
            do
              days = ''
              /* Days array */
              ae = JSON_findValue(etok,'days',HWTJ_ARRAY_TYPE)
              if ae <> '' then
              do
                aenum = JSON_getNumElem(ae)
                /* each array entry is the day name */
                do aeix = 0 by 1 while aeix < aenum
                  /* get next entry */
                  atok = JSON_getArrEntry(ae,aeix)
                  days = days||strip(left(JSON_getValEntry(atok),3))','
                end
                if days <> '' then
                  days = '('left(days,length(days)-1)')'
              end
              /* Daytime object */
              stime = ''
              ooe = JSON_findValue(oe,'timeOfDay',HWTJ_OBJECT_TYPE)
              if ooe <> '' then
              do
                stime = right(JSON_findValue(ooe,'hour',HWTJ_NUMBER_TYPE), ,
                        2,'0')||':'|| ,
                        right(JSON_findValue(ooe,'minute',HWTJ_NUMBER_TYPE), ,
                        2,'0')
              end
              /* Compose schedule details in single field */
              g.pout.o.8 = strip(stime days)
              if g.pout.o.8 = '' then
                g.pout.o.8 = stype
            end
            else if stype = 'IntervalTaskSchedule' then
            do
              ival = JSON_findValue(oe,'interval',HWTJ_NUMBER_TYPE)
              if datatype(ival,'W') then
              do
                /* interval is msec */
                ival = ival % 1000 /* use only whole seconds */
                dd = ival % (3600 * 24)
                rest = ival // (3600 * 24) /* remaining seconds of day */
                hh = right(rest % 3600,2,'0')
                mm = right((rest // 3600) % 60,2,'0')
                g.pout.o.8 = 'Every' dd'D' hh'H' mm'M'
              end
              if g.pout.o.8 = '' then
                g.pout.o.8 = stype
            end
            else
              g.pout.o.8 = stype
          end
          /* Actions array */
          ae = JSON_findValue(etok,'actions',HWTJ_ARRAY_TYPE)
          if ae <> '' then
            g.pout.o.9 = JSON_getNumElem(ae)
          else
            g.pout.o.9 = 0
          /* Sessions array */
          ae = JSON_findValue(etok,'affectedSession',HWTJ_ARRAY_TYPE)
          if ae <> '' then
          do
            aenum = JSON_getNumElem(ae)
            /* each array entry is the session name */
            do aeix = 0 by 1 while aeix < aenum
              /* get next entry */
              atok = JSON_getArrEntry(ae,aeix)
              g.pout.o.10 = g.pout.o.10||JSON_getValEntry(atok)','
            end
            g.pout.o.10 = left(g.pout.o.10,length(g.pout.o.10)-1)
          end
          else
            g.pout.o.10= 0
          /* Update column max values */
          do j = 1 to g.pout.0.0
            g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
          end
        end
        g.pout.0 = o
      end
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for scheduled tasks query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       ' CSM scheduled task overview:' g.pout.0 'tasks',sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_GetSysPaths                                               */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of PPRC paths for a given    */
/* storage system.                                                          */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_GetSysPaths: procedure expose g. (HWT_CONSTANTS)
  parse arg sys, hdr, fmt, delim, sort
  /* Check required parameter */
  fname = 'CSM_GetSysPaths(sys,hdr,fmt,delim,sort)'
  if sess = '' then
    return fatalError('** No system name specified for function' fname '**')
  /* Check format of system name, e.g. DS8000:BOX:2107.BRX71 */
  parse var sys stype ':BOX:' sname
  if sname = '' then
    return fatalError('** Invalid system format, specify <type>:BOX:<name> **')
  /* Define default sort */
  if sort = '' then
    sort = '2,5,6'  /* Sort by secondary system ID and LSS */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Storage Device overview */
  g.reqType = 'GET'
  /* Ensure to converts blanks to %20 in URL */
  g.reqPath = '/CSM/web/storagedevices/paths/'ConvBlanks(sys)
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Querying PPRC paths for system '"sys"' from" g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing LSS Pair path objects */
  /* initialize global output stem for formatted device summary output */
  call InitTable 'SrcSystem, LSS, SSID, WWNN, TgtSystem, LSS, SSID, WWNN, '||,
                 '#Paths, #Err, PortPairs(HexState)'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        o = g.pout.0 + 1
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the object */
        if onum > 0 then
        do
          /* convert some entries to hex, only positive whole number */
          g.pout.o.1 = JSON_findValue(etok,'sourceboxname',HWTJ_STRING_TYPE)
          g.pout.o.2 = JSON_findValue(etok,'sourcelss',HWTJ_NUMBER_TYPE)
          if datatype(g.pout.o.2,'W') then
            g.pout.o.2 = d2x(strip(g.pout.o.2,'L','-'),2)
          g.pout.o.3 = JSON_findValue(etok,'sourcessid',HWTJ_NUMBER_TYPE)
          if datatype(g.pout.o.3,'W') then
            g.pout.o.3 = d2x(strip(g.pout.o.3,'L','-'),4)
          g.pout.o.4 = JSON_findValue(etok,'sourcewwwn',HWTJ_STRING_TYPE)
          g.pout.o.5 = JSON_findValue(etok,'targetboxname',HWTJ_STRING_TYPE)
          g.pout.o.6 = JSON_findValue(etok,'targetlss',HWTJ_NUMBER_TYPE)
          if datatype(g.pout.o.6,'W') then
            g.pout.o.6 = d2x(strip(g.pout.o.6,'L','-'),2)
          g.pout.o.7 = JSON_findValue(etok,'targetssid',HWTJ_NUMBER_TYPE)
          if datatype(g.pout.o.7,'W') then
            g.pout.o.7 = d2x(strip(g.pout.o.7,'L','-'),4)
          g.pout.o.8 = JSON_findValue(etok,'targetwwwn',HWTJ_STRING_TYPE)
          g.pout.o.9 = JSON_findValue(etok,'numberofpaths',HWTJ_NUMBER_TYPE)
          g.pout.o.10= JSON_findValue(etok,'numberoferrorpaths', ,
                                      HWTJ_NUMBER_TYPE)
          /* ports and states entry is a comma separated string */
          sport = translate(JSON_findValue(etok,'pathsourceports', ,
                            HWTJ_STRING_TYPE),' ',',')
          tport = translate(JSON_findValue(etok,'pathtargetports', ,
                            HWTJ_STRING_TYPE),' ',',')
          pstate= translate(JSON_findValue(etok,'pathportstates', ,
                            HWTJ_STRING_TYPE),' ',',')
          /* compose port pairs field and convert to hex values */
          tmp = ''
          do i = 1 to words(sport)
            spnum = word(sport,i)
            if datatype(spnum,'W') then
              spnum = d2x(spnum,4)
            else
              spnum = '????'
            tpnum = word(tport,i)
            if datatype(tpnum,'W') then
              tpnum = d2x(tpnum,4)
            else
              tpnum = '????'
            stnum = word(pstate,i)
            if datatype(stnum,'W') then
              stnum = d2x(stnum,2)
            else
              stnum = '??'
            tmp = tmp||spnum':'tpnum'('stnum'),'
          end
          g.pout.o.11= strip(tmp,'T',',')
          /* Update column max values */
          do j = 1 to g.pout.0.0
            g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
          end
          g.pout.0 = o
        end
      end
    end aix /* end root array */
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for system path query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       " PPRC path query for system '"sys"':" g.pout.0 "LSS pairs",sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_GetSessCpSets                                             */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of CSM session copy sets.    */
/* The session name is a required parameter, cols is an optional comma      */
/* separated list of columns to be displayed for each volume. Valid cols:   */
/* ID, NAME, DEV, SEfficient, ZATTached, WWNN, PROTected                    */
/* Cols are displayed in specified order, default is ID, NAME, DEV          */
/* Invalid cols are skipped.                                                */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_GetSessCpSets: procedure expose g. (HWT_CONSTANTS)
  parse arg sess, cols, hdr, fmt, delim, sort
  /* Check required parameter */
  fname = 'CSM_GetSessCpSets(sess,cols,hdr,fmt,delim,sort)'
  if sess = '' then
    return fatalError('** No session name specified for function' fname '**')
  /* Compose col fields */
  fields = ''
  do while cols <> ''
    parse upper var cols field ',' cols
    field = strip(field)
    if left(field,2) = 'ID' then
      fields = fields 'VolID'
    else if left(field,4) = 'NAME' then
      fields = fields 'Name'
    else if left(field,3) = 'DEV' then
      fields = fields 'Dev'
    else if left(field,2) = 'SE' then
      fields = fields 'SE'
    else if left(field,4) = 'WWNN' then
      fields = fields 'WWNN'
    else if left(field,4) = 'ZATT' then
      fields = fields 'zAtt'
    else if left(field,4) = 'PROT' then
      fields = fields 'Prot'
  end
  fields = strip(fields)
  if fields = '' then
   fields = 'VolID Name Dev'   /* default columns */
  /* Define default sort */
  if sort = '' then
    sort = ''  /* No default sort since dev ID string sort is not hex sorted */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */

  /* Query first the session to get used volume roles and order */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/sessions/'ConvBlanks(sess)
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Querying volume roles of CSM session '"sess"' from" g.cUri "..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')
  /* Expecting JSON with a root Object containing sites array for session */
  /* Each obj in sites array contains roles on the site */
  /* It is assumed this is the order how volumes are listed in copy set arr */
  /* Define default volume roles */
  roles = ''
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_OBJECT_TYPE then
  do
    /* get array with site objects */
    stok = JSON_findValue(0,'sites',HWTJ_ARRAY_TYPE)
    /* get number of entries in the array  */
    snum = JSON_getNumElem(stok)
    if snum < 0 then
      return fatalError('** No site info found for session' sess '**')
    if g.verbose then
      say 'Found' snum 'elements in sites array'
    /* for each site, process the role information */
    do saix = 0 by 1 while saix < snum
      /* get next entry */
      etok = JSON_getArrEntry(stok,saix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if g.verbose then
          say 'Found' onum 'elements in site object' saix
        /* search specific entries in the object */
        if onum > 0 then
        do
          rtok = JSON_findValue(etok,'roles',HWTJ_ARRAY_TYPE)
          if rtok <> '' then
          do
            rnum = JSON_getNumElem(rtok)
            do raix = 0 by 1 while raix < rnum
              retok = JSON_getArrEntry(rtok,raix)
              roles = roles JSON_getValEntry(retok)
            end
          end
        end
      end
    end
  end  /* End session details query */
  if g.ShowInfo | g.Verbose then
    say "Volume role order in session '"sess"':" roles
  /* Define default roles if none found in session details */
  if strip(roles) = '' then
    roles = "V1 V2 V3 V4 V5 V6 V7 V8 V9"

  /* Query session copysets */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/sessions/'ConvBlanks(sess)'/copysets'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Querying copysets for CSM session '"sess"' from" g.cUri "..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing copyset objects       */
  /* Each copyset obj contains elements and a volume list array with   */
  /* volume objects containing details of the volume.                  */
  /* initialize global output stem for formatted device summary output */
  call InitTable 'V1-ID'                   /* has to be expanded later */
  head = ''  /* Marker with full header line */
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        /* this is the copy set object */
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        o = g.pout.0 + 1
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the copy set object */
        if onum > 0 then
        do
          cpvtok = JSON_findValue(etok,'volumelist',HWTJ_ARRAY_TYPE)
          if cpvtok = '' | left(cpvtok,2)='(n' then
            return fatalError('** Volume list object not found in object '||,
                               aix '**')
          cpvnum = JSON_getNumElem(cpvtok)
          /* Reinit table based on num vols in copyset and selected cols */
          if head = '' then
          do
            do i = 1 to cpvnum
              role = word(roles,i)
              do j = 1 to words(fields)
                field = word(fields,j)
                head = head||role'-'field','
              end
            end
            head = strip(head,'T',",")
            call InitTable head
          end
          /* Cycle all volume obj in array */
          vol = 0
          c = 0   /* col index */
          do aeix = 0 by 1 while aeix < cpvnum
            /* get next vol object */
            atok = JSON_getArrEntry(cpvtok,aeix)
            atype = JSON_getType(atok)
            if atype = HWTJ_OBJECT_TYPE then
            do
              vol = vol + 1
              /* Cycle all selected fields and lookup vol value */
              do f = 1 to words(fields)
                field = word(fields,f)
                c = c + 1
                if field = 'VolID' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'elementid',HWTJ_STRING_TYPE)
                else if field = 'Name' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'nickname',HWTJ_STRING_TYPE)
                else if field = 'Dev' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'devNum',HWTJ_STRING_TYPE)
                else if field = 'SE' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'spaceefficenttype',HWTJ_STRING_TYPE)
                else if field = 'zAtt' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'iszattached',HWTJ_BOOLEAN_TYPE)
                else if field = 'WWNN' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'volume_wwn',HWTJ_STRING_TYPE)
                else if field = 'Prot' then
                  g.pout.o.c = JSON_findValue(atok, ,
                               'isprotected',HWTJ_BOOLEAN_TYPE)
              end
            end
          end

          /* Update column max values */
          do j = 1 to g.pout.0.0
            g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
          end
        end
        g.pout.0 = o
      end
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for session copysets query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       " Copysets for session '"sess"':" g.pout.0,sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_GetSessBackups                                            */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of available backups for a   */
/* given CSM session.                                                       */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_GetSessBackups: procedure expose g. (HWT_CONSTANTS)
  parse arg sess, hdr, fmt, delim, sort
  /* Check required parameter */
  fname = 'CSM_GetSessBackups(sess,hdr,fmt,delim,sort)'
  if sess = '' then
    return fatalError('** No session name specified for function' fname '**')
  /* Define default sort */
  if sort = '' then
    sort = '6d'  /* Sort backups by timestamp descending */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Storage Device overview */
  g.reqType = 'GET'
  /* Ensure to converts blanks to %20 in URL */
  g.reqPath = '/CSM/web/sessions/'ConvBlanks(sess)
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Querying available backups for session '"sess"' from" g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Object containing session details */
  /* 'backupInfo' will contain an Array of Ojects with backup sequences */
  /* 'BackupResults' of a sequence is an Array of Objects with backup details */
  /* initialize global output stem for formatted device summary output */
  call InitTable 'RolePair, BackupID, #CpSets, Valid, BlkExp, Timestamp,'||,
                 'Retention, BackupTime'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_OBJECT_TYPE then
  do
    /* get array with backup sequences */
    bsa = JSON_findValue(0,'backupInfo',HWTJ_ARRAY_TYPE)
    /* get number of entries in the array  */
    bsanum = JSON_getNumElem(bsa)
    if bsanum < 0 then
      return fatalError('** No backup info found for session' sess '**')
    if g.verbose then
      say 'Found' bsanum 'elements in backupInfo sequence array'
    /* for each sequence, process the backup details */
    do bsaix = 0 by 1 while bsaix < bsanum
      /* get next entry */
      etok = JSON_getArrEntry(bsa,bsaix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if g.verbose then
          say 'Found' onum 'elements in backup sequence object' bsaix
        /* search specific entries in the object */
        if onum > 0 then
        do
          seq = JSON_findValue(etok,'backupSequence',HWTJ_STRING_TYPE)
          /* get array with backup tasks */
          bra = JSON_findValue(bsa,'BackupResults',HWTJ_ARRAY_TYPE)
          /* get number of entries in the array  */
          branum = JSON_getNumElem(bra)
          if g.verbose then
            say 'Found' branum 'elements in backupResults array'
          /* for each backup result, process the details */
          do braix = 0 by 1 while braix < branum
            /* get next entry */
            e2tok = JSON_getArrEntry(bra,braix)
            e2type = JSON_getType(e2tok)
            if e2type = HWTJ_OBJECT_TYPE then
            do
              o = g.pout.0 + 1
              g.pout.o.1 = seq
              g.pout.o.2 = JSON_findValue(e2tok,'backupID', ,
                           HWTJ_STRING_TYPE)
              g.pout.o.3 = JSON_findValue(e2tok,'numCopySets', ,
                           HWTJ_STRING_TYPE)
              g.pout.o.4 = JSON_findValue(e2tok,'valid', ,
                           HWTJ_BOOLEAN_TYPE)
              g.pout.o.5 = JSON_findValue(e2tok,'blockingExpansion', ,
                           HWTJ_STRING_TYPE)
              g.pout.o.6 = JSON_findValue(e2tok,'timestamp', ,
                           HWTJ_NUMBER_TYPE)
              g.pout.o.6 = ConvUnixTime(g.pout.o.6)
              g.pout.o.7 = JSON_findValue(e2tok,'retention', ,
                           HWTJ_STRING_TYPE)
              g.pout.o.8 = JSON_findValue(e2tok,'backupTime', ,
                           HWTJ_STRING_TYPE)
              g.pout.o.8 = ConvUnixTime(g.pout.o.8)
              /* Update column max values */
              do j = 1 to g.pout.0.0
                g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
              end
              g.pout.0 = o
            end
          end /* end backupResults array */
        end
      end
    end /* end backup sequence array */
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for session backup query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       " Available backups for session '"sess"':" g.pout.0 "backups",sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_GetSessCmd                                                */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of available commands for    */
/* given CSM session.                                                       */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field separation, sort options.          */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_GetSessCmd: procedure expose g. (HWT_CONSTANTS)
  parse arg sess, hdr, fmt, delim, sort
  fname = 'CSM_GetSessCmd(sess,hdr,fmt,delim,sort)'
  /* Check required parameter */
  if sess = '' then
    return fatalError('** No session name specified for function' fname '**')
  /* Define default sort */
  if sort = '' then
    sort = '1'  /* Sort commands column ascending */
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Compose command URL and body parms as required */
  g.reqType = 'GET'
  /* convert blanks to %20 in URL */
  g.reqPath = '/CSM/web/sessions/'ConvBlanks(sess)'/availablecommands'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say "Getting available commands for CSM session '"sess"' ..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing commands */
  /* initialize global output stem for formatted list of commands */
  call InitTable 'Command'
  type = JSON_getType(0)  /* Obtain entry type of root */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Available commands not found for session' sess '**')
    if g.verbose then
      say 'Found' anum 'elements in available commands array'
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      o = g.pout.0 + 1
      etok = JSON_getArrEntry(0,aix)
      g.pout.o.1 = JSON_getValEntry(etok)
      /* Update column max values */
      do j = 1 to g.pout.0.0
        g.pout.0.j = max(g.pout.0.j,length(g.pout.o.j))
      end
      g.pout.0 = o
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for available commands query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       " Available commands for session '"sess"':" g.pout.0 "commands",sort)

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_RunSessCmd                                                */
/*--------------------------------------------------------------------------*/
/* Procedure to issue an action command to a CSM session. It needs to be    */
/* called with the session name, the command and an optional parameter      */
/* required for the command, like the backup ID when                        */
/* recovering or restoring SGC backups.                                     */
/* Returns: 0 if command executed without error message                     */
/* Returns: 4 if command executed with one or more warning messages         */
/* Returns: 8 if command executed with one or more error messages           */
/* Returns:12 if command executed with one or more severe messages          */
/* Returns:16 if unkown severity char in message code                       */
/* Returns:-1 on error during processing request                            */
/*--------------------------------------------------------------------------*/
CSM_RunSessCmd: procedure expose g. (HWT_CONSTANTS)
  parse arg sess, cmd, oparm1
  fname = 'CSM_RunSessCmd(sess,cmd,parm)'
  /* Check required parameters */
  if sess = '' then
    return fatalError('** No session name specified for function' fname '**')
  if cmd = '' then
    return fatalError('** No command specified for function' fname '**')
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Compose command URL and body parms as required */
  g.reqType = 'POST'
  /* convert blanks to %20 in URL */
  g.reqPath = '/CSM/web/sessions/'ConvBlanks(sess)
  if oparm1 <> '' & pos('BACKUP',translate(cmd)) > 0 then
    /* currently all backups reside on H1 role */
    g.reqPath = g.reqPath'/backups/H1/'ConvBlanks(oparm1)
  g.reqBody = 'cmd='ConvBlanks(cmd)
  say g.cUri": Issuing command '"cmd"' to session '"sess"' ..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
return CheckCsmCmdResp()

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_RunHaCmd                                                  */
/*--------------------------------------------------------------------------*/
/* Procedure to issue an action for CSM server HA configuration.            */
/* A valid command is required, and remoteserver:port may be required for   */
/* the command. Username and password are only required for AddStandby cmd. */
/* Valid cmds: SetAsStandby,AddStandby,Reconnect,Takeover,RemoveStandby     */
/* Returns: 0 if HA command executed without error message                  */
/* Returns: 4 if HA command executed with one or more warning messages      */
/* Returns: 8 if HA command executed with one or more error messages        */
/* Returns:12 if HA command executed with one or more severe messages       */
/* Returns:16 if unkown severity char in message code                       */
/* Returns:-1 on error during processing request                            */
/*--------------------------------------------------------------------------*/
CSM_RunHaCmd: procedure expose g. (HWT_CONSTANTS)
  parse arg cmd, server, usr, pwd
  upper cmd
  port = ''
  fname = 'CSM_RunHaCmd(cmd,remoteserver:port,user,pwd)'
  /* Check required parameters */
  if cmd = 'SETASSTANDBY' | cmd = 'ADDSTANDBY' | cmd = 'REMOVESTANDBY' then
  do
    if server = '' then
      return fatalError('** Need remote server for function' fname '**')
    if cmd = 'ADDSTANDBY' & (usr = '' | pwd = '') then
      return fatalError('** Need user and password for function' fname '**')
  end
  /* extract optional port from server var */
  pos = lastpos(':',server)
  if pos > 1 then
  do
    port = substr(server,pos+1)
    server = left(server,pos-1)
  end
  if datatype(port,'W') then
  do
    if port < 1 | port > 65535 then
      return fatalError("** Invalid port '"port"' for function" fname "**")
  end
  else if port <> '' then
    return fatalError("** Invalid port '"port"' for function" fname "**")

  /* Compose command URL and body parms as required */
  g.reqType = 'PUT'
  if cmd = 'SETASSTANDBY' then
  do
    g.reqPath = '/CSM/web/system/ha/setServerAsStandby/'server
    if port <> '' then
      g.reqPath = g.reqPath'/'port
  end
  else if cmd = 'ADDSTANDBY' then
  do
    g.reqPath = '/CSM/web/system/ha/setStandbyServer/'server
    g.reqPath = g.reqPath'/'usr'/'pwd
    if port <> '' then
      g.reqPath = g.reqPath'/'port
  end
  else if cmd = 'RECONNECT' then
  do
    g.reqPath = '/CSM/web/system/ha/reconnect'
  end
  else if cmd = 'TAKEOVER' then
  do
    g.reqPath = '/CSM/web/system/ha/takeover'
  end
  else if cmd = 'REMOVESTANDBY' then
  do
    g.reqPath = '/CSM/web/system/ha/removeHaServer/'server
  end
  else
    return fatalError('** Need valid HA server command ('|| ,
           'SetAsStandby,AddStandby,Reconnect,Takeover,RemoveStandby'|| ,
           ') for function' fname '**')

  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  say g.cUri": Issuing HA server command '"cmd"' ..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
return CheckCsmCmdResp()

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_RunTaskCmd                                                */
/*--------------------------------------------------------------------------*/
/* Procedure to issue an action command to a CSM scheduled task. It needs   */
/* to be called with task ID, a supported task command, an optional         */
/* dateTime value and an optional sync flag. The optional parameters are    */
/* ignored if not valid for the task command.                               */
/* Returns: 0 if task command executed without error message                */
/* Returns: 4 if task command executed with one or more warning messages    */
/* Returns: 8 if task command executed with one or more error messages      */
/* Returns:12 if task command executed with one or more severe messages     */
/* Returns:16 if unkown severity char in message code                       */
/* Returns:-1 on error during processing request                            */
/*--------------------------------------------------------------------------*/
CSM_RunTaskCmd: procedure expose g. (HWT_CONSTANTS)
  parse arg taskid, cmd, datetime, sync
  upper cmd sync
  fname = 'CSM_RunTaskCmd(taskid,cmd,dateTime,sync)'
  /* Check required parameters */
  if datatype(taskid,'W') = 0 then
    return fatalError('** No task ID specified for function' fname '**')
  datetime = strip(datetime)
  if datetime <> '' then
  do
    tpos = pos('T',datetime)
    if tpos <> 11 | length(datetime) <> 16 then
      return fatalError('** Invalid date & time format, need '|| ,
             'yyyy-mm-ddThh-mm for function' fname '**')
  end
  if sync = '' | sync = '0' | sync = 'OFF' then
    sync = 0
  else
    sync = 1

  /* Compose command URL and body parms as required */
  g.reqType = 'POST'
  if cmd = 'DELETE' then
  do
    g.reqPath = '/CSM/web/sessions/scheduledtasks/delete/'taskid
  end
  else if cmd = 'DISABLE' then
  do
    g.reqPath = '/CSM/web/sessions/scheduledtasks/disable/'taskid
  end
  else if cmd = 'ENABLE' then
  do
    g.reqPath = '/CSM/web/sessions/scheduledtasks/enable/'taskid
    if datetime <> '' then
      g.reqPath = g.reqPath'/'datetime
  end
  else if cmd = 'RUN' then
  do
    g.reqPath = '/CSM/web/sessions/scheduledtasks/'taskid
    if datetime <> '' then
      g.reqPath = g.reqPath'/runat/'datetime
    else if sync then
      g.reqPath = g.reqPath'/synchronous'
  end
  else
    return fatalError('** Need valid task command ('|| ,
           'RUN,ENABLE,DISABLE,DELETE'|| ,
           ') for function' fname '**')

  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  say g.cUri": Issuing task command '"cmd"' to task ID '"taskid"' ..."
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
return CheckCsmCmdResp()

/*--------------------------------------------------------------------------*/
/* Procedure: CSM_ShowTask                                                  */
/*--------------------------------------------------------------------------*/
/* Procedure to query & print formatted output of task details for a given  */
/* task name or ID                                                          */
/* The optional display options are Header ON(1) or OFF(0), Formatting      */
/* ON(1) or OFF(0), delim char for field value separation.                  */
/* Returns: 0 if Query and output OK, -1 if not                             */
/*--------------------------------------------------------------------------*/
CSM_ShowTask: procedure expose g. (HWT_CONSTANTS)
  parse arg task, hdr, fmt, delim
  fname = 'CSM_ShowTask(task,hdr,fmt,delim)'
  /* Check required parameters */
  if taskid = '' then
    return fatalError('** No task ID/name specified for function' fname '**')
  /* Measure elapsed time */
  elapsec = Time(R) /* Reset timer */
  /* Query Storage Device overview */
  g.reqType = 'GET'
  g.reqPath = '/CSM/web/sessions/scheduledtasks'
  g.reqBody = ''
  if g.ShowInfo | g.verbose then
    say 'Querying CSM scheduled tasks from' g.cUri '...'
  if HTTP_sendRequest(g.reqType,g.reqPath,g.reqBody,g.outFile) <> 0 then
  do
    return fatalError('** Request failed **')
  end
  /* Parse the response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Array containing task objects */
  /* initialize global output stem for formatted device summary output */
  call InitTable 'Entry, Value'
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_ARRAY_TYPE then
  do
    /* get number of entries in the array  */
    anum = JSON_getNumElem(0)
    if anum < 0 then
      return fatalError('** Number of elements in array not determined **')
    if g.verbose then
      say 'Found' anum 'elements in array'
    taskids = ''
    tasknames = ''
    /* for each array entry, process the json data type */
    do aix = 0 by 1 while aix < anum
      /* get next entry */
      etok = JSON_getArrEntry(0,aix)
      etype = JSON_getType(etok)
      if etype = HWTJ_OBJECT_TYPE then
      do
        o = g.pout.0 + 1
        /* get number of entries in the object */
        onum = JSON_getNumElem(etok)
        if onum < 0 then
          return fatalError('** Number of elements in object not determined **')
        if g.verbose then
          say 'Found' onum 'elements in object' aix
        /* search specific entries in the object */
        if onum > 0 then
        do
          taskid = JSON_findValue(etok,'id',HWTJ_NUMBER_TYPE)
          taskname = JSON_findValue(etok,'name',HWTJ_STRING_TYPE)
          /* save ID and name for lookup later on */
          taskids = taskids taskid
          tasknames = tasknames taskname
          if task = taskid | task = taskname then
          do
            /* found requested task, print details */
            if g.verbose then
              say 'Found requested task' taskid':' taskname
            o = 1
            g.pout.o.1 = 'Name'
            g.pout.o.2 = taskname
            o = o + 1
            g.pout.o.1 = 'ID'
            g.pout.o.2 = taskid
            o = o + 1
            g.pout.o.1 = 'Description'
            g.pout.o.2 = JSON_findValue(etok,'description',HWTJ_STRING_TYPE)
            /* Compose schedule */
            o = o + 1
            g.pout.o.1 = 'Schedule'
            /* Schedule object */
            oe = JSON_findValue(etok,'schedule',HWTJ_OBJECT_TYPE)
            if oe <> '' then
            do
              stype = JSON_findValue(oe,'type',HWTJ_STRING_TYPE)
              /* Compose schedule details in single field */
              if stype = 'NoTaskSchedule' then
                g.pout.o.2 = 'No Schedule'
              else if stype = 'WeeklyTaskSchedule' then
              do
                days = ''
                /* Days array */
                ae = JSON_findValue(etok,'days',HWTJ_ARRAY_TYPE)
                if ae <> '' then
                do
                  aenum = JSON_getNumElem(ae)
                  /* each array entry is the day name */
                  do aeix = 0 by 1 while aeix < aenum
                    /* get next entry */
                    atok = JSON_getArrEntry(ae,aeix)
                    days = days||strip(left(JSON_getValEntry(atok),3))','
                  end
                  if days <> '' then
                    days = '('left(days,length(days)-1)')'
                end
                /* Daytime object */
                stime = ''
                ooe = JSON_findValue(oe,'timeOfDay',HWTJ_OBJECT_TYPE)
                if ooe <> '' then
                do
                  stime = right(JSON_findValue(ooe,'hour',HWTJ_NUMBER_TYPE), ,
                          2,'0')||':'|| ,
                          right(JSON_findValue(ooe,'minute',HWTJ_NUMBER_TYPE), ,
                          2,'0')
                end
                /* Compose schedule details in single field */
                g.pout.o.2 = strip(stime days)
                if g.pout.o.2 = '' then
                  g.pout.o.2 = stype
              end
              else if stype = 'IntervalTaskSchedule' then
              do
                ival = JSON_findValue(oe,'interval',HWTJ_NUMBER_TYPE)
                if datatype(ival,'W') then
                do
                  /* interval is msec */
                  ival = ival % 1000 /* use only whole seconds */
                  dd = ival % (3600 * 24)
                  rest = ival // (3600 * 24) /* remaining seconds of day */
                  hh = right(rest % 3600,2,'0')
                  mm = right((rest // 3600) % 60,2,'0')
                  g.pout.o.2 = 'Every' dd'D' hh'H' mm'M'
                end
                if g.pout.o.2 = '' then
                  g.pout.o.2 = stype
              end
              else
                g.pout.o.2 = stype
            end
            o = o + 1
            g.pout.o.1 = 'RunTaskOnSuccess'
            g.pout.o.2=JSON_findValue(etok,'runtaskonsuccess',HWTJ_NUMBER_TYPE)
            o = o + 1
            g.pout.o.1 = 'RunTaskOnFailure'
            g.pout.o.2=JSON_findValue(etok,'runtaskonfailure',HWTJ_NUMBER_TYPE)
            o = o + 1
            g.pout.o.1 = 'PePackageOnError'
            g.pout.o.2 = JSON_findValue(etok,'logOnFailure',HWTJ_BOOLEAN_TYPE)
            /* Actions array */
            o = o + 1
            g.pout.o.1 = 'Actions'
            ae = JSON_findValue(etok,'actions',HWTJ_ARRAY_TYPE)
            if ae <> '' then
            do
              /* each array entry is action object with various entries */
              aenum = JSON_getNumElem(ae)
              g.pout.o.2 = aenum
              digs = length(aenum)
              /* print all action details */
              do aeix = 0 by 1 while aeix < aenum
                atok = JSON_getArrEntry(ae,aeix)
                atype = JSON_getType(atok)
                if atype = HWTJ_OBJECT_TYPE then
                do
                  o = o + 1
                  g.pout.o.1 = ' *Action('right(aeix+1,digs,'0')')'
                  aonum = JSON_getNumElem(atok)
                  str = ''
                  do aoix = 0 by 1 while aoix < aonum
                    /* Get next object entry token and name */
                    parse value JSON_getObjEntry(atok,aoix) with oetok 5 oename
                    oeval = JSON_getValEntry(oetok)
                    if oename = "timeout" then
                    do
                      /* convert action timeout to minutes like in GUI */
                      if datatype(oeval,'W') then
                        oeval = (oeval % 1000) % 60 'min'
                    end
                    str = str||oename'='oeval','
                  end
                  g.pout.o.2 = strip(str,'T',',')
                end
              end
            end
            /* Report State of task depending on 3 flags */
            o = o + 1
            g.pout.o.1 = 'State'
            enabled = JSON_findValue(etok,'enabled',HWTJ_BOOLEAN_TYPE)
            running = JSON_findValue(etok,'running',HWTJ_BOOLEAN_TYPE)
            penAppr = JSON_findValue(etok,'pendingApproval',HWTJ_BOOLEAN_TYPE)
            upper enabled running penAppr
            if penAppr = 'TRUE' then
              g.pout.o.2 = 'PendAppr'
            else if running = 'TRUE' then
              g.pout.o.2 = 'Running'
            else if enabled = 'TRUE' then
              g.pout.o.2 = 'Enabled'
            else
              g.pout.o.2 = 'Disabled'
            o = o + 1
            g.pout.o.1 = 'NextRun'
            g.pout.o.2 = JSON_findValue(etok,'nextRun',HWTJ_NUMBER_TYPE)
            g.pout.o.2 = ConvUnixTime(g.pout.o.2)
            o = o + 1
            g.pout.o.1 = 'LastRun'
            g.pout.o.2 = JSON_findValue(etok,'lastRan',HWTJ_NUMBER_TYPE)
            g.pout.o.2 = ConvUnixTime(g.pout.o.2)
            /* Messages array */
            o = o + 1
            g.pout.o.1 = 'Messages'
            ae = JSON_findValue(etok,'messages',HWTJ_ARRAY_TYPE)
            if ae <> '' then
            do
              /* each array entry is msg object, sorted asc by timestamp */
              aenum = JSON_getNumElem(ae)
              g.pout.o.2 = aenum
              /* get last 9 messages */
              limit = max(0,aenum-9)
              digs = length(aenum)
              do aeix = aenum-1 by -1 while aeix >= limit
                /* get next object */
                atok = JSON_getArrEntry(ae,aeix)
                atype = JSON_getType(atok)
                if atype = HWTJ_OBJECT_TYPE then
                do
                  o = o + 1
                  g.pout.o.1 = ' *Msg('right(aeix+1,digs,'0')')'
                  mtime = JSON_findValue(atok,'baseDate',HWTJ_NUMBER_TYPE)
                  mesg = JSON_findValue(atok,'msg',HWTJ_STRING_TYPE)
                  mres = JSON_findValue(atok,'resultText',HWTJ_STRING_TYPE)
                  g.pout.o.2 = ConvUnixTime(mtime)':'mesg':'mres
                end
              end
            end
            g.pout.0 = o
          end
        end
      end
    end aix
    if g.pout.0 > 0 then
    do
      /* Update column max values */
      do i = 1 to g.pout.0
        /* lookup task names for success or failure tasks */
        if g.pout.i.1 = 'RunTaskOnSuccess' | ,
           g.pout.i.1 = 'RunTaskOnFailure' then
        do
          if datatype(g.pout.i.2,'W') then
          idx = wordpos(g.pout.i.2,taskids)
          if idx > 0 then
            g.pout.i.2 = g.pout.i.2':'word(tasknames,idx)
        end
        do j = 1 to g.pout.0.0
          g.pout.0.j = max(g.pout.0.j,length(g.pout.i.j))
        end
      end
    end
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for scheduled tasks query **')
return PrintTable(hdr,fmt,delim,g.cUri|| ,
       ' (Query:' format(time(R),,2) 'sec.):'|| ,
       " CSM scheduled task details for '"task"'")

/*--------------------------------------------------------------------------*/
/* Procedure: CheckCsmCmdResp                                               */
/*--------------------------------------------------------------------------*/
/* Procedure to validate JSON response for an issued command.               */
/* It will return non 0 if no Info Message was received.                    */
/* Returns: 0 if command executed without error message                     */
/* Returns: 4 if command executed with one or more warning messages         */
/* Returns: 8 if command executed with one or more error messages           */
/* Returns:12 if command executed with one or more severe messages          */
/* Returns:16 if unkown severity char in message code                       */
/* Returns:-1 on error during processing request                            */
/*--------------------------------------------------------------------------*/
CheckCsmCmdResp: procedure expose g. (HWT_CONSTANTS)
  /* Parse the latest response to initialize the parser handle */
  if JSON_parse(g.resBody) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* Expecting JSON with a root Object containing response fields */
  type = JSON_getType(0)  /* Obtain entry type of root object */
  if type = HWTJ_OBJECT_TYPE then
  do
    /* get number of entries in the object  */
    onum = JSON_getNumElem(0)
    if onum < 0 then
      return fatalError('** Number of elements in object not determined **')
    if g.verbose then
      say 'Received' onum 'elements in object'
    msgcode = JSON_findValue(0,'msg',HWTJ_STRING_TYPE)
    msgtext = JSON_findValue(0,'msgTranslated',HWTJ_STRING_TYPE)
    say 'Response ('format(time(R),,2) 'sec.):' msgtext
    msgsev = right(msgcode,1)
    if msgsev = 'I' then return 0
    else if msgsev = 'W' then return 4
    else if msgsev = 'E' then return 8
    else if msgsev = 'S' then return 12
    else return 16
  end
  else
    return fatalError('** Unexpected JSON type' JSON_getTypeName(type) ,
                      'for command response **')
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: InitTable                                                     */
/*--------------------------------------------------------------------------*/
/* Procedure to init the global stem used to compose a formatted output     */
/* table. Call the procedure with the titles of the required columns.       */
/* The second stem index is used for the columns.                           */
/* Returns: 0 if output OK, -1 if not                                       */
/*--------------------------------------------------------------------------*/
InitTable: procedure expose g.
  parse arg header
  i = 0
  g.pout. = ''
  g.pout.0 = 0   /* Number of rows in table */
  g.pout.0. = 0  /* Max length of entries in field */
  do while header <> ''
    parse var header colname ',' header
    i = i + 1
    g.pout.0.i.name = strip(colname)
  end
  g.pout.0.0 = i /* Number of columns in table */
  do i = 1 to g.pout.0.0
    g.pout.0.i = length(g.pout.0.i.name) /* initialize col length from name */
  end
return

/*--------------------------------------------------------------------------*/
/* Procedure: PrintTable                                                    */
/*--------------------------------------------------------------------------*/
/* Procedure to print a formatted table from the global parser output stem  */
/* The display options are Header ON or OFF, Delim Char, Formatting ON or   */
/* OFF and an optional title line. If the column name starts with # it will */
/* be right formatted (for numbers). The optional sort specifies the column */
/* number with optional A or D sort direction (Default is Ascending).       */
/* Returns: 0 if output OK, -1 if not                                       */
/*--------------------------------------------------------------------------*/
PrintTable: procedure expose g.
  parse arg hdr, fmt, delim, title, sort
  upper hdr fmt sort
  /* Initialize output options as requested */
  if hdr = '' then
    hdr = g.tHeader  /* Use global setting as default */
  if hdr = '0' | hdr = 'OFF' then
    hdr = 0
  else
    hdr = 1
  if fmt = '' then
    fmt = g.tFormat  /* Use global setting as default */
  if fmt = '0' | fmt = 'OFF' then
    fmt = 0
  else
    fmt = 1
  if delim == '' then /* compare identical to allow space */
    delim = strip(g.tDelim) /* Use global setting as default */
  delim = left(delim,1)     /* Ensure delim is 1 char        */
  /* Check output stem is correctly initialized */
  if datatype(g.pout.0,'W') = 0 then
    return fatalError('** Output table row count not initialized **')
  if datatype(g.pout.0.0,'W') = 0 then
    return fatalError('** Output table column count not initialized **')
  /* Extract sort options */
  srule. = ''
  r = 0
  do i = 1 by 1 while sort <> ''
    parse var sort scol ',' sort
    sdir = right(scol,1)
    if datatype(sdir,'W') = 0 then
      /* Remove order from column if specified */
      scol = left(scol,length(scol)-1)
    if datatype(scol,'W') then
    do
      if scol > 0 & scol <= g.pout.0.0 then
      do
        /* valid column number for sort option */
        r = r + 1
        srule.r = scol /* column number for sort rule */
        if sdir <> 'D' then
          srule.r.A = 1  /* Ascending */
        else
          srule.r.A = 0  /* Descending */
      end
    end
  end
  srule.0 = r
  /* Create sorted index for order of lines */
  sortidx. = ''
  sortidx.0 = 0
  sortidx.0.0 = srule.0
  if srule.0 > 0 then
  do
    sc1 = srule.1        /* first order column */
    sa1 = srule.1.A      /* first order ascending */
    do i = 1 to g.pout.0
      inserted = 0       /* Marker if line was inserted */
      do j = 1 to sortidx.0 while inserted = 0
        /* compare first order col against sorted index */
        if (sa1 = 0 & g.pout.i.sc1 > sortidx.j.1) | ,
           (sa1 = 1 & g.pout.i.sc1 < sortidx.j.1) then
        do
          inserted = 1
        end
        else if g.pout.i.sc1 == sortidx.j.1 then
        do k = 2 to srule.0
          /* compare next col to order */
          sc = srule.k
          sa = srule.k.A
          if (sa = 0 & g.pout.i.sc > sortidx.j.k) | ,
             (sa = 1 & g.pout.i.sc < sortidx.j.k) then
          do
            inserted = 1
            leave
          end
          else if g.pout.i.sc <> sortidx.j.k then
            leave        /* do not compare deeper if order ok */
        end
      end j
      if inserted then
      do
        j = j -1
        /* shift rest of sorted index stem */
        do k = sortidx.0 to j by -1
          idx = k + 1
          do l = 0 to sortidx.0.0
            /* shift all fields in sorted index stem */
            sortidx.idx.l = sortidx.k.l
          end
        end
        /* Insert line */
        sortidx.j.0 = i /* save line number of output table */
        do l = 1 to sortidx.0.0
          /* save fields for all cols to order */
          sc = srule.l
          sortidx.j.l = g.pout.i.sc
        end
        sortidx.0 = sortidx.0 + 1
      end
      else
      do
        /* Add line to end of sorted index stem */
        idx = sortidx.0 + 1
        sortidx.0 = idx
        sortidx.idx.0 = i /* save line number of output table */
        do l = 1 to sortidx.0.0
          /* save fields for all cols to order */
          sc = srule.l
          sortidx.idx.l = g.pout.i.sc
        end
      end
    end i
  end

  /* print output stem with formatted table */
  hsep = ''   /* header separator line */
  do i = 0 to g.pout.0
    line = ''
    do j = 1 to g.pout.0.0
      if i = 0 then
      do
        /* check column size is initialized */
        if datatype(g.pout.0.j,'W') = 0 then
          return fatalError('** Output table column' j ' not initialized **')
        /* Compose sort marker for column */
        sortstr = ''
        do k = 1 to srule.0
          if srule.k = j then
          do
            if srule.k.A then
              sortstr = 'A'k
            else
              sortstr = 'D'k
          end
        end
        /* compose header line and table width */
        if fmt then
        do
          /* Print with space formatting */
          line = line||left(g.pout.0.j.name,g.pout.0.j)||delim
          hsep = hsep||center(sortstr,g.pout.0.j,'-')||delim
        end
        else
        do
          /* Print without space formatting */
          line = line||g.pout.0.j.name||delim
          hsep = hsep||center(sortstr,length(g.pout.0.j.name),'-')||delim
        end
      end
      else
      do
        /* Select row to print based on sorted index */
        if sortidx.0 >= i then
          row = sortidx.i.0
        else
          row = i
        if fmt then
        do
          /* Print with space formatting */
          if left(g.pout.0.j.name,1) = '#' then  /* right formatted */
            line = line||right(g.pout.row.j,g.pout.0.j)||delim
          else
            line = line||left(g.pout.row.j,g.pout.0.j)||delim
        end
        else
        do
          /* Print without space formatting */
          line = line||g.pout.row.j||delim
        end
      end
    end /* end composing all fields for line */
    line = left(line,length(line)-1) /* remove last char from line */
    if i = 0 then
    do
      if hdr then
      do
        /* Print optional title only if header is enabled */
        if title <> '' then
          say title
        say line
        hsep = left(hsep,length(hsep)-1) /* remove last char from hsep */
        say hsep                         /* print header separator */
      end
    end
    else
      say line
  end
return 0


/*--------------------------------------------------------------------------*/
/*                      HTTP-related functions                              */
/*--------------------------------------------------------------------------*/
/* These HTTP_xxx functions are located together for ease of reference      */
/* and are used to demonstrate how this portion of the zOS Web Enablement   */
/* Toolkit can be used to setup connections and issue requests.             */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* Function: HTTP_getToolkitConstants                                       */
/*--------------------------------------------------------------------------*/
/* Init constants used by the web toolkit (for return codes, etc)           */
/* via the HWTCONST toolkit api.                                            */
/* Returns: 0 if toolkit constants accessed, -1 if not                      */
/*--------------------------------------------------------------------------*/
HTTP_getToolkitConstants:
  /***********************************************/
  /* Ensure that the toolkit host command is     */
  /* available in your REXX environment (no harm */
  /* done if already present).  Do this before   */
  /* your first toolkit api invocation.  Also,   */
  /* ensure no conflicting signal-handling in    */
  /* cases of running in USS environments.       */
  /***********************************************/
  if g.verbose then
    say 'Setting hwtcalls on, syscalls sigoff'
  call hwtcalls 'on'
  call syscalls 'SIGOFF'
  /************************************************/
  /* Call the HWTCONST toolkit api.  This should  */
  /* make all toolkit-related constants available */
  /* to procedures via expose of (HWT_CONSTANTS)  */
  /************************************************/
  if g.verbose then
    say 'Including HWT Constants...'
  address hwthttp "hwtconst ",
                  "ReturnCode ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwtconst', RexxRC, ReturnCode
    return fatalError('** hwtconst (hwthttp) failure **')
  end /* endif hwtconst failure */
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_sendRequest                                               */
/*--------------------------------------------------------------------------*/
/* Wrapper function to handle connection setup & test, as well as request   */
/* setup and submit. Request output is saved to output file if specified    */
/* The response translation can optionally be enforced. Default is A2E      */
/* translation enabled, if /download is found in path it will be disabled   */
/* since binary stream data is expected from CSM server.                    */
/* Note: If no actual token was found in credential DS, a new one is        */
/* requested first from the server and saved, before submitting actual req  */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_sendRequest:
parse arg reqType, reqPath, reqBody, outfile, a2eResBody
  /* First check for proper HTTP request type */
  upper reqType a2eResBody
  select
    when reqType = 'GET' then myType = HWTH_HTTP_REQUEST_GET
    when reqType = 'PUT' then myType = HWTH_HTTP_REQUEST_PUT
    when reqType = 'POST' then myType = HWTH_HTTP_REQUEST_POST
    when reqType = 'DELETE' then myType = HWTH_HTTP_REQUEST_DELETE
    when reqType = 'HEAD' then myType = HWTH_HTTP_REQUEST_HEAD
    otherwise do
      return fatalError('** Unsupported HTTP Request method' ,
             '(GET,PUT,POST,DELETE,HEAD):' reqType)
    end
  end
  /* Check if specified output file is valid type and can be allocated */
  if outfile <> '' then
  do
    if pos('/',outfile) > 0 then
    do
      /* OMVS filename defined */
      if allocateDD(g.outDD,outfile,"PATHDISP(KEEP,DELETE) "|| ,
       "PATHOPTS(OWRONLY,OCREAT) PATHMODE(SIRUSR,SIWUSR) "|| ,
       "FILEDATA(BINARY)") <> 0 then
      do
        return fatalError('** File' outfile 'could not be allocated **')
      end
      x = bpxwdyn("FREE FI('"g.outDD"')")
    end
    else
    do
      /* member or full DSN defined */
      return fatalError("** Output file '"outfile"'"|| ,
             " does not contain USS path **")
    end
  end
  /* Set response body translation based on optional parameter (default on) */
  if a2eResBody = '0' | a2eResBody = 'OFF' then
    a2eResBody = 0
  else if a2eResBody = '' then
  do
    /* Automatically disable response body translation based on request path */
    /* Disable ASCII to EBCEDIC translation for all CSM /download requests */
    if pos('/DOWNLOAD',translate(reqPath)) > 0 then
      a2eResBody = 0
    else
      a2eResBody = 1
  end
  else
    a2eResBody = 1
  if g.showInfo then
  do
    say 'Sending request "'reqType'" "'reqPath'" to' g.cUri':'g.cPort
    say 'Request Body: "'reqBody'"'
    if a2eResBody then
      say 'Response translation: A2E , Output File: "'outfile'"'
    else
      say 'Response translation: NONE, Output File: "'outfile'"'
  end

  /* check and obtain a connection handle  */
  if g.cHandle = '' then
  do
    /* Initialize Connection handle */
    if HTTP_init(HWTH_HANDLETYPE_CONNECTION) <> 0 then
      return fatalError('** Connection could not be initialized **')
    /* Set the necessary options before connecting to the server  */
    if HTTP_setupConnection(HWTH_SSL_USE) <> 0 then
      return fatalError('** Connection failed to be set up **')
    /* Connect to the HTTP server  */
    if HTTP_connect() <> 0 then
      return fatalError('** Connection failed **')
  end
  /* Check and obtain a request handle (run setup only once) */
  if g.rHandle = '' then
  do
    if HTTP_init(HWTH_HANDLETYPE_HTTPREQUEST) <> 0 then
      return fatalError('** Request could not be initialized **')
    /* Set standard header and authentication for request handle */
    /* This usually needs to be setup only once for the request handle */
    if HTTP_setRequestHeaders(g.rHandle) <> 0 then
      return fatalError('** Request Header options could not be setup **')
    g.reqBody = ''
    if HTTP_setRequestBody() <> 0 then
      return fatalError('** Request Body options could not be setup **')
    if HTTP_setRespHdrBody() <> 0 then
      return fatalError('** Response Header/Body options could not be setup **')
  end
  if g.rToken = '' then
  do
    /* obtain credentials and optional saved token */
    if updtCredentials(g.AuthFile) <> 0 then
      return fatalError('** Request Authentication could not be obtained **')
  end
  RefreshToken:
  if g.rToken = '' then
  do
    /* No valid token saved, request new one */
    /* CSM does not require basic auth setup to request auth. tokens,   */
    /* but it needs the user credentials for the token in the req. body */
    if HTTP_requestToken() <> 0 then
      return fatalError('** Authorization token could not be received **')
  end
  /* Ensure the available token will be set to request header */
  if g.rTokenSet = 0 then
  do
    if HTTP_setToken() <> 0 then
      return fatalError('** Authorization token setup failed **')
  end
  /* Setup request method, path and body */
  if HTTP_setupRequest(myType, reqPath, reqBody, a2eResBody) <> 0 then
    return fatalError('** Request could not be setup **')
  /* Submit request */
  if HTTP_request() <> 0 then
    return fatalError('** Submitted request failed **')
  /* Check response code and act upon as required */
  select
    when g.resCode = '200' then           /* HTTP OK */
    do
      if g.showInfo | g.verbose then
      do
        say 'Request response ('g.resSize' Bytes):' g.resType
        if g.resType <> 'OCTET-STREAM' then
          say g.resBody
        else
          say 'Stream data (not displayed)'
      end
      /* Save response to file if specified */
      if outfile <> '' then
      do
        if g.showInfo | g.verbose then
          say "Saving response data to '"outfile"' ..."
        /* Reallocate OMVS filename for overwrite */
        if allocateDD(g.outDD,outfile,"PATHDISP(KEEP,DELETE) "|| ,
         "PATHOPTS(OWRONLY,OCREAT,OTRUNC) PATHMODE(SIRUSR,SIWUSR) "|| ,
         "FILEDATA(BINARY)") <> 0 then
        do
          return fatalError('** File' outfile 'could not be allocated **')
        end
        /* break down long stream to 80 chars for writing without error */
        str = g.resBody
        do i = 1 by 1 while length(str) > 80
          parse var str mydata.i =81 str
        end
        mydata.i = str
        mydata.0 = i
        address MVS "EXECIO" mydata.0 "DISKW" g.outDD ,
                    "(OPEN STEM mydata. FINIS)"
        myrc = RC
        x = bpxwdyn("FREE FI('"g.outDD"')")
        if myrc = 0 then
        do
          if g.showInfo | g.verbose then
            say "Saved response data to '"outfile"'"
        end
        else
          return fatalError("** Could not save response data to '"outfile,
                 ||"', RC:" myrc)
      end
      return 0
    end
    when g.resCode = '401' then           /* Unauthorized */
    do
      if g.rToken <> '' then
      do
        /* Saved token was invalid */
        /* Repeat request after new token requested */
        g.rToken = ''
        g.rTokenSet = 0
        signal RefreshToken
      end
    end
    otherwise
    do
      if g.showInfo | g.verbose then
      do
        say 'Request response ('g.resSize' Bytes):' g.resType
        say g.resBody
      end
    end
  end
return fatalError('** Bad response status:' ,
       g.resCode "(Reason:" g.resReasonCode")")

/*--------------------------------------------------------------------------*/
/* Function: HTTP_requestToken                                              */
/*--------------------------------------------------------------------------*/
/* Wrapper function to request a token for subsequent requests              */
/* Note: If a CSM Token was obtained, it can be reused for 2 hours before   */
/* it expires.                                                              */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_requestToken:
  /* Request token for credentials */
  if g.verbose then
    say 'Requesting new token for credentials'
  if HTTP_setupRequest(HWTH_HTTP_REQUEST_POST, ,
     "/CSM/web/system/v1/tokens", ,
     "username="g.rUsername"&password="g.rPassword,1) <> 0 then
    return fatalError('** Authorization token request setup failed **')
  /* Submit Token request */
  if HTTP_request() <> 0 then
    return fatalError('** Authorization token request failed **')
  /* Check response code      */
  select
    when g.resCode = '200' then           /* HTTP OK */
    do
      /* get token */
      /* Use JSON Parser services to process the data returned   */
      if JSON_parse(g.resBody) <> 0 then
         return fatalError('** Error parsing authorization token response **')
      /* Extract specific data and save it */
      g.rToken = JSON_findValue(0, 'token', HWTJ_STRING_TYPE)
      /* Validate token received and save it */
      if g.rToken = '' | left(g.rToken,2)='(n' then
      do
        /* No token received in response, credentials probably invalid */
        g.rUsername = ''
        g.rPassword = ''
        /* clear saved credentials again to avoid invalid cred are reused */
        if g.ShowInfo | g.verbose then
          say "No token received for credentials, clearing credential file"
        call updtCredentials g.AuthFile, "CLEAR"
        return fatalError('** No token returned for provided credentials **')
      end
      /* Save received token */
      if updtCredentials(g.AuthFile) <> 0 then
         return fatalError('** Request Authentication could not be saved **')
      /* Add token to request header setup */
      if HTTP_setToken() <> 0 then
         return fatalError('** Request header could not be setup with token **')
    end
    otherwise do
      if g.resBody <> "" then say "Response:" g.resBody
      return fatalError('** Bad response status:' ,
             g.resCode "(Reason:" g.resReasonCode")")
    end
    /* Clear response buddy for subsequent requests */
    g.resBody = ''
  end
return 0

/*--------------------------------------------------------------------------*/
/* Function: HTTP_setToken                                                  */
/*--------------------------------------------------------------------------*/
/* Wrapper function to set or update Token in Header for request            */
/* Note: If a CSM Token was obtained, it can be reused for 2 hours before   */
/* it expires in the request handle                                         */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setToken:
  /* Add/update token in request header definitions */
  if g.verbose then
    say 'Adding token to request header setup'
  if datatype(g.reqHeader.0,'W') = 0 then
    g.reqHeader.0 = 0
  do i = 1 to g.reqHeader.0
    /* find header line with existing token definition */
    if left(g.reqHeader.i,13) = "X-Auth-Token:" then
      leave
  end
  g.reqHeader.i = "X-Auth-Token:" g.rToken
  /* i > stem count if not found */
  if i > g.reqHeader.0 then
    g.reqHeader.0 = i
  g.rTokenSet = 0
  if HTTP_setRequestHeaders(g.rHandle) <> 0 then
    return fatalError('** Request Header could not be setup',
                      'with authorization token **')
  g.rTokenSet = 1
return 0

/*--------------------------------------------------------------------------*/
/* Function: HTTP_init                                                      */
/*--------------------------------------------------------------------------*/
/* Create a handle of the designated type, via the HWTHINIT toolkit api.    */
/* Populate the corresponding global variable with the result               */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_init:
  parse arg HandleType .
  /* Call the HWTHINIT toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthinit ",
                  "ReturnCode ",
                  "HandleType ",
                  "HandleOut ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthinit', RexxRC, ReturnCode, DiagArea.
    return fatalError('** hwthinit failure **')
  end
  if HandleType == HWTH_HANDLETYPE_CONNECTION then
    g.cHandle = HandleOut
  else
    g.rHandle = HandleOut
return 0  /* end Function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_setupConnection                                           */
/*--------------------------------------------------------------------------*/
/* Sets the necessary connection options, via the HWTHSET toolkit api.      */
/* The global variable g.cHandle orients the api as to the scope            */
/* of the option(s).                                                        */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setupConnection:
  parse arg ssltype
  if ssltype <> HWTH_SSL_USE then
    ssltype = HWTH_SSL_NONE
  if g.verbose then
  do
    /*****************************************************************/
    /* Set the HWT_OPT_g.verbose option, if appropriate.             */
    /* This option is handy when developing an application (but may  */
    /* be undesirable once development is complete).  Inner workings */
    /* of the toolkit are traced by messages written to standard     */
    /* output, or optionally redirected to file (by use of the       */
    /* HWTH_OPT_VERBOSE_OUTPUT option).                              */
    /*****************************************************************/
    say '* Set connection option HWTH_OPT_VERBOSE: HWTH_VERBOSE_ON'
    ReturnCode = -1
    DiagArea. = ''
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.cHandle ",
                    "HWTH_OPT_VERBOSE ",
                    "HWTH_VERBOSE_ON ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_VERBOSE) failure **')
    end /* endif hwthset failure */

    /***********************************************************************/
    /* Setup trace file for connection if defined                          */
    /* The DD statement for the trace can specify one of the following:    */
    /* - Pre-allocated DSN with following recommended attributes:          */
    /*   * Physical sequential (DSORG=PS)                                  */
    /*   * Unblocked variable or undefined record fmt (RECFM=V or RECFM=U) */
    /*   * Unspecified (or zero-valued) block size and record length,      */
    /*     so that the default values will be set when the DD is opened    */
    /*   * Expandable (nonzero primary and secondary extents)              */
    /* - A USS file                                                        */
    /***********************************************************************/
    alocFile = getAlocFile(g.traceDD)
    if alocFile <> '' then
    do
      /* file Pre-allocated, update global trace file name */
      if g.TraceFile <> alocFile & g.TraceFile <> '' then
        say 'Specified trace file ignored:' g.TraceFile
      g.TraceFile = alocFile
      say 'Using pre-allocated trace file:' g.TraceFile
    end
    else if g.TraceFile <> '' then
    do
      if pos('/',g.TraceFile) > 0 then
      do
        /* Allocate trace file if not allocated yet */
        say 'Allocating requested trace file:' g.TraceFile
        if allocateDD(g.traceDD,g.TraceFile,"PATHDISP(KEEP,KEEP) "|| ,
          "PATHOPTS(OWRONLY,OCREAT) PATHMODE(SIRWXU)") <> 0 then
          return fatalError("** '"g.TraceFile"' could not be allocated **")
      end
      else
      do
        /* Allocate trace DSN if not allocated yet */
        say 'Allocating requested trace DSN:' g.TraceFile
        if allocateDD(g.traceDD,g.TraceFile,"UNIT(3390) SPACE(5,5) CYL "|| ,
          "RECFM(V)") <> 0 then
          return fatalError("** '"g.TraceFile"' could not be allocated **")
      end
    end
    /* Set Trace DD for verbose output */
    if g.TraceFile <> '' then
    do
      say 'Set HWTH_OPT_VERBOSE_OUTPUT for connection:' g.TraceFile
      DiagArea. = ''
      address hwthttp "hwthset ",
                      "ReturnCode ",
                      "g.cHandle ",
                      "HWTH_OPT_VERBOSE_OUTPUT ",
                      "g.traceDD ",
                      "DiagArea."
      RexxRC = RC
      if HTTP_isError(RexxRC,ReturnCode) then
      do
        call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode, DiagArea.
        return fatalError( '** hwthset (HWTH_OPT_VERBOSE_OUTPUT) failure **' )
      end /* endif hwthset failure */
    end
  end /* endif script invocation requested g.verbose */
  /* Set URI for connection */
  if g.verbose then
    say '* Set connection option HWTH_OPT_URI:' g.cUri
  if strip(g.cUri) = '' then
    return fatalError('** Connection URI not defined **')
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "HWTH_OPT_URI ",
                  "g.cUri ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_URI) failure **')
  end  /* endif hwthset failure */
  /* Set PORT for connection */
  if g.verbose then
    say '* Set connection option HWTH_OPT_PORT:' g.cPort
  if strip(g.cPort) = '' then
    return fatalError('** Connection Port not defined **')
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "HWTH_OPT_PORT ",
                  "g.cPort ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_PORT) failure **')
  end  /* endif hwthset failure */
  /* Set SSL for connection with key DB file */
  if g.verbose then
    say '* Set connection option HWTH_OPT_USE_SSL:' ssltype
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "HWTH_OPT_USE_SSL ",
                  "ssltype ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_USE_SSL) failure **')
  end  /* endif hwthset failure */
  /* Set additional SSL options if SSL handshake requested */
  if ssltype = HWTH_SSL_USE then
  do
    /* check which key option to use */
    if g.cKeyRing <> '' then
    do
      sslkeytype = 'HWTH_SSLKEYTYPE_KEYRINGNAME'
      sslkey = g.cKeyRing
    end
    else
    do
      sslkeytype = 'HWTH_SSLKEYTYPE_KEYDBFILE'
      sslkey = g.cKeyDb
      if strip(g.cDbStash) = '' then
        return fatalError('** Key database stash file not defined **')
    end
    if strip(sslkey) = '' then
      return fatalError('** Neither key ring nor key database defined **')

    /* Make required SSL settings */
    if g.verbose then
      say '* Set connection option HWTH_OPT_SSLKEYTYPE:' sslkeytype
    sslkeytype = value(sslkeytype)
    ReturnCode = -1
    DiagArea. = ''
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.cHandle ",
                    "HWTH_OPT_SSLKEYTYPE ",
                    "sslkeytype ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_SSLKEYTYPE) failure **')
    end  /* endif hwthset failure */
    if g.verbose then
      say '* Set connection option HWTH_OPT_SSLKEY:' sslkey
    ReturnCode = -1
    DiagArea. = ''
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.cHandle ",
                    "HWTH_OPT_SSLKEY ",
                    "sslkey ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_SSLKEY) failure **')
    end  /* endif hwthset failure */
    /* Set additional options for key db usage */
    if sslkeytype = HWTH_SSLKEYTYPE_KEYDBFILE then
    do
      if g.verbose then
        say '* Set connection option HWTH_OPT_SSLKEYSTASHFILE:' g.cDbStash
      ReturnCode = -1
      DiagArea. = ''
      address hwthttp "hwthset ",
                      "ReturnCode ",
                      "g.cHandle ",
                      "HWTH_OPT_SSLKEYSTASHFILE ",
                      "g.cDbStash ",
                      "DiagArea."
      RexxRC = RC
      if HTTP_isError(RexxRC,ReturnCode) then
      do
        call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
        return fatalError('** hwthset (HWTH_OPT_SSLKEYSTASHFILE) failure **')
      end
      /* Specify authentication label in key db */
      if strip(g.cCertLab) = '' then
        return fatalError('** Certificate label not defined **')
      if g.verbose then
        say '* Set connection option HWTH_OPT_SSLCLIENTAUTHLABEL:' g.cCertLab
      ReturnCode = -1
      DiagArea. = ''
      address hwthttp "hwthset ",
                      "ReturnCode ",
                      "g.cHandle ",
                      "HWTH_OPT_SSLCLIENTAUTHLABEL ",
                      "g.cCertLab ",
                      "DiagArea."
      RexxRC = RC
      if HTTP_isError(RexxRC,ReturnCode) then
      do
        call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
        return fatalError('** hwthset (HWTH_OPT_SSLCLIENTAUTHLABEL) failure **')
      end  /* endif hwthset failure */
    end  /* end options for key db usage */

    /* Allow only TLS 1.2 and 1.3 */
    if g.verbose then
      say '* Set connection option HWTH_OPT_SSLVERSION: HWTH_SSLVERSION_TLSv12'
    ReturnCode = -1
    DiagArea. = ''
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.cHandle ",
                    "HWTH_OPT_SSLVERSION ",
                    "HWTH_SSLVERSION_TLSv12 ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_SSLVERSION) failure **')
    end  /* endif hwthset failure */
    if g.verbose then
      say '* Set connection option HWTH_OPT_SSLVERSION: HWTH_SSLVERSION_TLSv13'
    ReturnCode = -1
    DiagArea. = ''
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.cHandle ",
                    "HWTH_OPT_SSLVERSION ",
                    "HWTH_SSLVERSION_TLSv13 ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_SSLVERSION) failure **')
    end  /* endif hwthset failure */
  end /* endif Use ssl  */
  /***********************************************************************/
  /* Set HWTH_OPT_COOKIETYPE                                             */
  /*   Enable the cookie engine for this connection.  Any "eligible"     */
  /*   stored cookies will be resent to the host on subsequent           */
  /*   interactions automatically.                                       */
  /***********************************************************************/
  if g.verbose then
    say '* Set connection option HWTH_OPT_COOKIETYPE: HWTH_COOKIETYPE_SESSION'
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "HWTH_OPT_COOKIETYPE ",
                  "HWTH_COOKIETYPE_SESSION ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
    do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_COOKIETYPE) failure **')
    end  /* endif hwthset failure */
  if g.verbose then
    say 'Connection setup successful'
return 0  /* end subroutine */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_connect                                                   */
/*--------------------------------------------------------------------------*/
/* Connect to the configured domain (host) via the HWTHCONN toolkit api.    */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_connect:
  if g.verbose then
    say 'Issue HTTP Connection'
  /* Call the HWTHCONN toolkit api  */
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthconn ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
    do
    call HTTP_surfaceDiag 'hwthconn', RexxRC, ReturnCode
    return fatalError('** hwthconn failure **')
    end
  if g.verbose then
    say 'HTTP connection (hwthconn) successful'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_disconnect                                                */
/*--------------------------------------------------------------------------*/
/* Disconnect from configured domain (host) via the HWTHDISC toolkit api.   */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_disconnect:
  if g.verbose then
    say 'Issue HTTP Disconnection'
  /* Call the HWTHDISC toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthdisc ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthdisc', RexxRC, ReturnCode
    return fatalError('** hwthdisc failure **')
  end /* endif hwthdisc failure */
  if g.verbose then
    say 'HTTP disconnect (hwthdisc) successful'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_terminate                                                 */
/*--------------------------------------------------------------------------*/
/* Release the designated Connection or Request handle via the              */
/* HWTHTERM toolkit api.                                                    */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_terminate:
  parse arg handleIn,forceOption
  if g.verbose then
    say 'Terminat handle (hwthterm) with option' forceOption
  /* Call the HWTHTERM toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthterm ",
                  "ReturnCode ",
                  "handleIn ",
                  "forceOption ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthterm', RexxRC, ReturnCode
    return fatalError('** hwthterm failure **')
  end  /* endif hwthterm failure */
  if g.verbose then
    say 'Terminated handle (hwthterm) successfully'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_setupRequest                                              */
/*--------------------------------------------------------------------------*/
/* Sets the necessary request options.  The global variable g.rHandle       */
/* orients the api as to the scope of the option(s).                        */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setupRequest:
  parse arg ReqMeth, ReqPth, ReqBdy, ResTransl
  upper ResTransl
  /* Set response body translation based on parameter (default on) */
  if ResTransl = '0' | a2eResBody = 'OFF' then
    ResTransl = 0
  else
    ResTransl = 1

  /* Set HTTP Request method */
  if g.verbose then
    say '* Set request option HWTH_OPT_REQUESTMETHOD:' ReqMeth
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_REQUESTMETHOD ",
                  "ReqMeth ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError ('hwthset (HWTH_OPT_REQUESTMETHOD) failure **')
  end  /* endif hwthset failure */

  /* Set the request URI Path as specified for the ressource */
  if g.verbose then
    say '* Set request option HWTH_OPT_URI:' ReqPth
  if strip(ReqPth) = '' then
    return fatalError('** Request URI path not defined **')
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_URI ",
                  "ReqPth ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_URI) failure **')
  end  /* endif hwthset failure */

  /* Set the request body as specified */
  ReturnCode = -1
  DiagArea. = ''
  if g.verbose then
  do
    /* Avoid password verbose in request body */
    if pos('password',ReqBdy) = 0 then
      say '* Set request option HWTH_OPT_REQUESTBODY:' ReqBdy
    else
      say '* Set request option HWTH_OPT_REQUESTBODY:'
  end
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_REQUESTBODY ",
                  "ReqBdy ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_REQUESTBODY) failure **')
  end /* endif hwthset failure */

  /* Set the request body as specified */
  if HTTP_TranslateBody(ResTransl) <> 0 then
    return fatalError('** Response translation could not be set **')

  if g.verbose then
    say 'Request setup successful'
return 0   /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_request                                                   */
/*--------------------------------------------------------------------------*/
/* Make the configured Http request via the HWTHRQST toolkit api.           */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_request:
  if g.verbose then
    say 'Submitting HTTP request and waiting for response...'
  ReturnCode = -1
  DiagArea. = ''
  /* Call the HWTHRQST toolkit api.  */
  address hwthttp "hwthrqst ",
                  "ReturnCode ",
                  "g.cHandle ",
                  "g.rHandle ",
                  "HttpStatusCode ",
                  "HttpReasonCode ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthrqst', RexxRC, ReturnCode
    return fatalError('** hwthrqst failure **')
  end  /* endif hwthrqst failure */
  /****************************************************************/
  /* The ReturnCode indicates merely whether the request was made */
  /* (and response received) without error.  The origin server's  */
  /* response, of course, is another matter.  The HttpStatusCode  */
  /* and HttpReasonCode record how the server responded.  Any     */
  /* header(s) and/or body included in that response are to be    */
  /* found in the variables which we established earlier.         */
  /****************************************************************/
  g.resCode = strip(HttpStatusCode,'L',0)
  g.resReasonCode = strip(HttpReasonCode)
  if g.verbose then
  do
    say 'Request completed'
    say 'HTTP Status Code         :' g.resCode
    say 'HTTP Response Reason Code:' g.resReasonCode
  end
  /* Get type of returned data */
  g.resType = ''
  g.resSize = '?'
  if datatype(g.resHeaders.0,'W') then
  do i = 1 to g.resHeaders.0
    /* check if JSON type
       stem.n = header name, stem.n.1 = header value
       Content-Type: application/json
       Content-Type: application/octet-stream
    */
    if g.verbose then
      say 'HTTP Response header' i':' g.resHeaders.i':' g.resHeaders.i.1
    hname = translate(g.resHeaders.i)
    if hname = 'CONTENT-TYPE' then
      parse upper var g.resHeaders.i.1 ctg '/' g.resType .
    else if hname = 'CONTENT-LENGTH' then
      g.resSize = g.resHeaders.i.1
  end
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Procedure: HTTP_surfaceDiag                                              */
/*--------------------------------------------------------------------------*/
/* Surface input error information.                                         */
/* Note that when the RexxRC is nonzero, the ToolkitRC and DiagArea         */
/* content are moot and are suppressed (so as to not mislead).              */
/*--------------------------------------------------------------------------*/
HTTP_surfaceDiag: procedure expose DiagArea.
  parse arg who, rexxRC, ToolkitRC
  say
  say '***HTTP-ERROR*** ('who') at time:' Time()
  /* Toolkit returns integer?, convert to hex to match documentation */
  if datatype(ToolkitRC) = 'W' then
    if ToolkitRC > 0 then ToolkitRC = d2x(ToolkitRC)
  say 'Rexx RC: 'rexxRC', Toolkit ReturnCode:' ToolkitRC
  say 'DiagArea.Service:' DiagArea.HWTH_service
  say 'DiagArea.ReasonCode:' DiagArea.HWTH_ReasonCode
  say 'DiagArea.ReasonDesc:' DiagArea.HWTH_ReasonDesc
  say
return /* end procedure */

/*--------------------------------------------------------------------------*/
/* Procedure: HTTP_setRequestAuth                                           */
/*--------------------------------------------------------------------------*/
/* Set Basic Authentication for request                                     */
/* Note: For CSM API this is only needed if the auth token process          */
/* is not used (not preferred). This function is not used currently.        */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setRequestAuth: procedure expose DiagArea. g. (HWT_CONSTANTS)
  parse arg Handle, User, Pwd
  if g.verbose then
    say'* Set request option HWTH_OPT_HTTPAUTH: HWTH_HTTPAUTH_BASIC'
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "Handle ",
                  "HWTH_OPT_HTTPAUTH ",
                  "HWTH_HTTPAUTH_BASIC ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
    do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_HTTPAUTH) failure **')
  end  /* endif hwthset failure */

  /* Set Username */
  if g.verbose then
    say'* Set request option HWTH_OPT_USERNAME' User
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "Handle ",
                  "HWTH_OPT_USERNAME ",
                  "User ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
    do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_USERNAME) failure **')
  end  /* endif hwthset failure */
  /* Set Password */
  if g.verbose then
    say'* Set request option HWTH_OPT_PASSWORD' left('',length(Pwd),'*')
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                   "ReturnCode ",
                   "Handle ",
                   "HWTH_OPT_PASSWORD ",
                   "Pwd ",
                   "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
     do
     call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
     return fatalError('** hwthset (HWTH_OPT_PASSWORD) failure **')
  end  /* endif hwthset failure */
  if g.verbose then
    say 'Request authentication setup successful'
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: HTTP_setRequestHeaders                                        */
/*--------------------------------------------------------------------------*/
/* Add appropriate Request Headers, by first building an "SList", and then  */
/* and then setting the HWTH_OPT_HTTPHEADERS option of the Request with     */
/* that list.                                                               */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setRequestHeaders: procedure expose DiagArea. g. (HWT_CONSTANTS)
  parse arg Handle
  /* check if headers specified in globals */
  if datatype(g.reqHeader.0,'W') = 0 then
    return 0
  else if g.reqHeader.0 < 1 then
    return 0
  SList = ''
  /* Create a brand new SList and specify the first header  */
  ReturnCode = -1
  DiagArea. = ''
  if g.verbose then
    say '* Create new SList for request header option:' g.reqHeader.1
  address hwthttp "hwthslst ",
                  "ReturnCode ",
                  "Handle ",
                  "HWTH_SLST_NEW ",
                  "SList ",
                  "g.reqHeader.1 ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthslst', RexxRC, ReturnCode
    return fatalError('** hwthslst (HWTH_SLST_NEW) failure **')
  end  /* endif hwthslst failure */
  /* Append additional Header settings to the SList */
  do i = 2 to g.reqHeader.0
    if g.verbose then
      say '* Append to SList header option:' g.reqHeader.i
    address hwthttp "hwthslst ",
                   "ReturnCode ",
                   "Handle ",
                   "HWTH_SLST_APPEND ",
                   "SList ",
                   "g.reqHeader.i ",
                   "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthslst', RexxRC, ReturnCode, DiagArea.
      return fatalError('** hwthslst (HWTH_SLST_APPEND) failure **')
    end /* endif hwthslst failure */
  end
  /* Set the request headers with the just-produced list */
  if g.verbose then
    say '* Set HWTH_OPT_HTTPHEADERS to SList'
  ReturnCode = -1
  DiagArea. = ''
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "Handle ",
                  "HWTH_OPT_HTTPHEADERS ",
                  "SList ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_HTTPHEADERS) failure **')
  end  /* endif hwthset failure */
  if g.verbose then
    say 'Request header setup successful'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function: HTTP_setRequestBody                                            */
/*--------------------------------------------------------------------------*/
/* Set the necessary attributes to set the request body                     */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setRequestBody:
  /* Have the toolkit convert the request body from EBCDIC to ASCII */
  /* This conversion is necessary that CSM server understands body parms */
  ReturnCode = -1
  DiagArea. = ''
  if g.verbose then
    say '* Set request body option HWTH_OPT_TRANSLATE_REQBODY:' ,
        'HWTH_XLATE_REQBODY_E2A'
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_TRANSLATE_REQBODY ",
                  "HWTH_XLATE_REQBODY_E2A ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_TRANSLATE_REQBODY) failure  **')
  end /* endif hwthset failure */
  if g.verbose then
    say 'Request body setup successful'
return 0

/*--------------------------------------------------------------------------*/
/* Function: HTTP_setRespHdrBody                                            */
/*--------------------------------------------------------------------------*/
/* Set options and variables for the response Hdr & Body                    */
/* Returns: 0 if successful, -1 if not                                      */
/*--------------------------------------------------------------------------*/
HTTP_setRespHdrBody:
  /* Set the stem variable for receiving response headers  */
  ReturnCode = -1
  DiagArea. = ''
  if g.verbose then
    say '* Set response header option HWTH_OPT_RESPONSEHDR_USERDATA'
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_RESPONSEHDR_USERDATA ",
                  "g.resHeaders. ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_RESPONSEHDR_USERDATA) failure **')
  end /* endif hwthset failure */
  /* Set the variable for receiving response body  */
  ReturnCode = -1
  DiagArea. = ''
  if g.verbose then
    say '* Set response body option HWTH_OPT_RESPONSEBODY_USERDATA'
  address hwthttp "hwthset ",
                  "ReturnCode ",
                  "g.rHandle ",
                  "HWTH_OPT_RESPONSEBODY_USERDATA ",
                  "g.resBody ",
                  "DiagArea."
  RexxRC = RC
  if HTTP_isError(RexxRC,ReturnCode) then
  do
    call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
    return fatalError('** hwthset (HWTH_OPT_RESPONSEBODY_USERDATA) failure **')
  end /* endif hwthset failure */
return 0

/*--------------------------------------------------------------------------*/
/* Function: HTTP_TranslateBody                                             */
/*--------------------------------------------------------------------------*/
/* Enables or disables the translation of the response body from ASCII      */
/* to EBCEDIC. This is required if text data is return that should be       */
/* parsed later on.                                                         */
/* This must be disabled if binary stream data is expected, otherwise the   */
/* byte stream becomes unusable (eg if file data is received)               */
/* Returns: -1 if any toolkit error is indicated, 0 otherwise               */
/*--------------------------------------------------------------------------*/
HTTP_TranslateBody:
  parse upper arg enable
  if enable = '' | enable = '0' | enable = 'OFF' then
    xlate = 'HWTH_XLATE_RESPBODY_NONE'
  else
    xlate = 'HWTH_XLATE_RESPBODY_A2E'
  /* Change setting only if different from active setting */
  if g.resA2E <> value(xlate) then
  do
    ReturnCode = -1
    DiagArea. = ''
    if g.verbose then
      say '* Set request option HWTH_OPT_TRANSLATE_RESPBODY:' xlate
    xlate = value(xlate)
    address hwthttp "hwthset ",
                    "ReturnCode ",
                    "g.rHandle ",
                    "HWTH_OPT_TRANSLATE_RESPBODY ",
                    "xlate ",
                    "DiagArea."
    RexxRC = RC
    if HTTP_isError(RexxRC,ReturnCode) then
    do
      call HTTP_surfaceDiag 'hwthset', RexxRC, ReturnCode
      return fatalError('** hwthset (HWTH_OPT_TRANSLATE_RESPBODY) failure **')
    end /* endif hwthset failure */
    g.resA2E = xlate
  end
return 0

/*--------------------------------------------------------------------------*/
/* Function: HTTP_isError                                                   */
/*--------------------------------------------------------------------------*/
/* Check the input processing codes.                                        */
/* Note that if the input RexxRC is nonzero, then the toolkit return code   */
/* is moot (the toolkit function was likely not even invoked). If the       */
/* toolkit return code is relevant, check it against the set of  HWTH_xx  */
/* return codes for evidence of error. This set is ordered:                 */
/* HWTH_OK < HWTH_WARNING < ...                                             */
/* with remaining codes indicating error, so we may check via single        */
/* Returns: -1 if any toolkit error is indicated, 0 otherwise               */
/*--------------------------------------------------------------------------*/
HTTP_isError:
  parse arg RexxRC, ToolkitRC
  if RexxRC <> 0 then
    return 1
  ToolkitRC = strip(ToolkitRC,'L',0)
  /* Toolkit returns integer while constants are hex */
  if datatype(ToolkitRC,'W') then
    if ToolkitRC > 0 then ToolkitRC = d2x(ToolkitRC)
  if ToolkitRC == '' then
    return 0
  if ToolkitRC <= HWTH_WARNING then
    return 0
return 1  /* end function */



/*--------------------------------------------------------------------------*/
/*                      JSON-related functions                              */
/*--------------------------------------------------------------------------*/
/* These JSON_xxx functions are located together for ease of reference      */
/* and are used to demonstrate how this portion of the zOS Web Enablement   */
/* Toolkit can be used in conjunction with the Http-related functions.      */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* Function: JSON_print                                                     */
/*--------------------------------------------------------------------------*/
/* Wrapper function to init the JSON parser and format the JSON             */
/* output in a stem variable g.resData                                      */
/* Input is the JSON text and filter can be used to limit output to         */
/* specific named entries only. The name filter will be used only for root  */
/* entries and each entry must be quoted to allow explicit comparision.     */
/* Filter example: '"name","description","state"'                           */
/* Returns: -1 if JSON paring not possible, 0 otherwise                     */
/*--------------------------------------------------------------------------*/
JSON_print:
  parse arg jsontext, filter
  if g.ShowInfo then
    say 'Formatting JSON text...'
  /* Use JSON Parser services to process the data returned   */
  if JSON_parse(jsontext) <> 0 then
    return fatalError('** Error while parsing returned data **')

  /* format the json string starting at the root */
  g.resData.0 = 0
  call print printtype(0,,filter)
  if g.ShowInfo then
  do
    if filter <> '' then
      say 'Filtered JSON text with:' filter
    else
      say 'Formatted JSON text:'
  end
  do x = 1 to g.resData.0
    say g.resData.x
  end
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: printtype (recursive use)                                     */
/*--------------------------------------------------------------------------*/
/* Call the specific printing routine for the json data type for the        */
/* element represented by the passed in token and optional name and filter  */
/*--------------------------------------------------------------------------*/
printtype: procedure expose g. (HWT_CONSTANTS)
  parse arg tok, name, filt
  /* get the json data type */
  type = JSON_getType(tok)
  if g.verbose then
    say "Found type for token:" JSON_getTypeName(type)

  /* call the processing routine for that data type */
  if type = HWTJ_OBJECT_TYPE then
  do
    if filt <> '' & name <> '' then
    do
      /* print nested object if name matches filter */
      if pos(dq(name,0),filt) > 0 then
        return printobject(tok,name)
      else
        return ''
    end
    else
      return printobject(tok,name,filt)
  end
  else if type = HWTJ_ARRAY_TYPE then
  do
    if filt <> '' & name <> '' then
    do
      /* print nested array if name matches filter */
      if pos(dq(name,0),filt) > 0 then
        return printarray(tok,name)
      else
        return ''
    end
    else
      return printarray(tok,name,filt)
  end
  else if type = HWTJ_STRING_TYPE then
  do
    /* Print entry only if it matches the filter */
    if filt = '' | pos(dq(name,0),filt) > 0 then
      return printstring(tok,name)
    else
      return ''
  end
  else if type = HWTJ_NUMBER_TYPE then
  do
    /* Print entry only if it matches the filter */
    if filt = '' | pos(dq(name,0),filt) > 0 then
      return printnumber(tok,name)
    else
      return ''
  end
  else if type = HWTJ_BOOLEAN_TYPE then
  do
    /* Print entry only if it matches the filter */
    if filt = '' | pos(dq(name,0),filt) > 0 then
      return printboolean(tok,name)
    else
      return ''
  end
  else if type = HWTJ_NULL_TYPE then
  do
    if g.pArr=1 then
      return 'null'
    else
    do
      /* Print entry only if it matches the filter */
      if filt = '' | pos(dq(name,0),filt) > 0 then
        return dq(name)': null'
      else
        return ''
    end
  end
  return '** JSON type unknown **'
return

/*--------------------------------------------------------------------------*/
/* Procedure: printobject (recursive use)                                   */
/*--------------------------------------------------------------------------*/
/* Handle printing for a json object type                                   */
/*--------------------------------------------------------------------------*/
printobject: procedure expose g. (HWT_CONSTANTS)
  parse arg objtok, name, filt

  /* get number of entries in the object */
  entries = JSON_getNumElem(objtok)
  if g.verbose then
    say 'Found' entries 'elements in object'
  if entries < 0 then
    cleanup('** Number of elements in object not determined **')

  /* enclose output of an object in braces indenting the content */
  closing = ''
  if entries = 0 then closing = g.pCBrac||g.pCchar
  if length(name) > 0 then
    call print dq(name)': 'g.pOBrac||closing
  else
    call print g.pOBrac||closing

  /* Set formatting hints for recursion to come   */
  g.pIndent = g.pIndent+g.pCols
  arrest = g.pArr
  g.pArr = 0

  /* for each entry, process the json data type */
  do i = 0 by 1 while i < entries
    parse value JSON_getObjEntry(objtok,i) with vtok 5 entryname
    if i < entries - 1 then
      comma = g.pCchar
    else
      comma = ''
    call print printtype(vtok,entryname,filt) || comma
  end

  /* Restore original formatting hints */
  g.pIndent = g.pIndent - g.pCols
  g.pArr = arrest
  closing = ''
  if entries > 0 then closing = g.pCBrac
return closing

/*--------------------------------------------------------------------------*/
/* Procedure: printarray  (recursive use)                                   */
/*--------------------------------------------------------------------------*/
/* Handle printing for a json array type                                    */
/*--------------------------------------------------------------------------*/
printarray: procedure expose g. (HWT_CONSTANTS)
  parse arg atok, name, filt

  /* get number of entries in the array  */
  entries = JSON_getNumElem(atok)
  if g.verbose then
    say 'Found' entries 'elements in array'
  if entries < 0 then
    cleanup('** Number of elements in array not determined **')

  /* enclose output of an array in brackets indenting the content */
  closing = ''
  if entries = 0 then closing = g.pCBrak||g.pCchar
  if g.pArr=0 then
     call print dq(name)': 'g.pOBrak||closing
   else
     call print g.pOBrak||closing

  /* Set formatting hints for recursion to come   */
  g.pIndent=g.pIndent+g.pCols
  arrest=g.pArr
  g.pArr=1

  /* for each entry, process the json data type */
  do aix = 0 by 1 while aix < entries
    /* get next entry */
    vtok = JSON_getArrEntry(atok,aix)

    /* process that entry type */
    if aix < entries - 1 then
      comma=g.pCchar
    else
      comma=''
    call print printtype(vtok,,filt) || comma
  end

  /* Restore original formatting hints */
  g.pIndent=g.pIndent-g.pCols
  g.pArr=arrest
  closing = ''
  if entries > 0 then closing = g.pCBrak
return closing

/*--------------------------------------------------------------------------*/
/* Procedure: printnumber                                                   */
/*--------------------------------------------------------------------------*/
/* Handle printing for a json number type                                   */
/*--------------------------------------------------------------------------*/
printnumber: procedure expose g.
  parse arg vtok, name

  /* get the numeric value as string */
  jvalue = JSON_getValEntry(vtok)

  /* format the output line */
  if g.pArr=1 then
     return jvalue
  else
     return dq(name)': '||jvalue

/*--------------------------------------------------------------------------*/
/* Procedure: printboolean                                                  */
/*--------------------------------------------------------------------------*/
/* Handle printing for a json boolean type                                  */
/*--------------------------------------------------------------------------*/
printboolean: procedure expose g.
  parse arg vtok, name

  /* get the boolean value */
  jvalue = JSON_getBoolEntry(vtok)

  /* format the output line */
  if g.pArr=1 then
    return jvalue
  else
    return dq(name)': '||jvalue

/*--------------------------------------------------------------------------*/
/* Procedure: printstring                                                   */
/*--------------------------------------------------------------------------*/
/* Handle printing for a json string type                                   */
/*--------------------------------------------------------------------------*/
printstring: procedure expose g.
  parse arg vtok, name

  /* get the string value */
  jvalue = JSON_getValEntry(vtok)

  /* format the output line */
  if g.pArr=1 then
    return dq(jvalue,0)
  else
    return dq(name)': '|| dq(jvalue,0)

/*--------------------------------------------------------------------------*/
/* Procedure: dq                                                            */
/*--------------------------------------------------------------------------*/
/* Quote the argument for printing functions                                */
/*--------------------------------------------------------------------------*/
dq: procedure expose g.
  parse arg str, pad
  if pad='' then
    pad=g.pNamewidth
  if length(str)>0 then
  do
    str=translate(str,'.',xrange('00'x,'3f'x))
    if g.pQchar='' then
    do
      ReturnCode = -1
      DiagArea. = ''
      address hwtjson "hwtjesct ",
                      "ReturnCode ",
                      "HWTJ_DECODE ",
                      "str ",
                      "str ",
                      "DiagArea."
      RexxRC = RC
      if JSON_isError(RexxRC,ReturnCode) then
      do
        call JSON_surfaceDiag 'hwtjesct', RexxRC, ReturnCode
        cleanup('** hwtjesct failure **')
      end
    end
  end

  if pad=0 | length(str)>pad+2 then
    return g.pQchar||str||g.pQchar
  else
    return left(g.pQchar||str||g.pQchar,pad+3)

/*--------------------------------------------------------------------------*/
/* Procedure: print                                                         */
/*--------------------------------------------------------------------------*/
/* Print function to prefix the input string with the proper indentation    */
/*--------------------------------------------------------------------------*/
print: procedure expose g.
  parse arg mesg, fd
  /* Add indent to message */
  mesg = copies(' ',g.pIndent)mesg
  if g.pEsc = 1 then
  do
    mesg=translate(mesg,'-   ',g.pOBrak||g.pCBrak||g.pOBrac||g.pCBrac)
    if mesg = '' then return
    if mesg = '-' then mesg=''
  end
  else
  do
    if strip(strip(mesg,,g.pCchar)) = '' then return
  end

  /* write to global stem  for later print  */
  if datatype(g.resData.0,'W') = 0 then g.resData.0 = 0
  x = g.resData.0 + 1
  g.resData.x = mesg
  g.resData.0 = x
return



/*--------------------------------------------------------------------------*/
/* Function: JSON_initParser                                                */
/*--------------------------------------------------------------------------*/
/* Initializes the global g.pHandle variable via call to toolkit service    */
/* HWTJINIT.                                                                */
/* Returns: 0 if successful, -1 if unsuccessful                             */
/*--------------------------------------------------------------------------*/
JSON_initParser:
  /* Call the HWTJINIT toolkit api.  */
  if g.verbose then
    say 'Initializing Json Parser'
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjinit ",
                  "ReturnCode ",
                  "handleOut ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    call JSON_surfaceDiag 'hwtjinit', RexxRC, ReturnCode
    return fatalError('** hwtjinit failure **')
  end  /* endif hwtjinit failure */
  g.pHandle = handleOut

  if g.verbose then
    say 'Json Parser initialization succeeded'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_parse                                                    */
/*--------------------------------------------------------------------------*/
/* Parses the input text body (which should be syntactically correct        */
/* JSON text) via call to toolkit service HWTJPARS.                         */
/* Returns: 0 if successful, -1 if unsuccessful                             */
/*--------------------------------------------------------------------------*/
JSON_parse:
  parse arg jsonTextBody
  /* try parse only if http response type was JSON */
  if g.resType = "OCTET-STREAM" then
    return fatalError('** OCTET-STREAM data cannot be parsed **')
  else if g.resType <> 'JSON' then
    return fatalError("** Last response is not JSON, but '"g.resType"' **")
  else if g.pDisp then
    say jsonTextBody

  /* first check if parse handle initialized */
  if g.pHandle = '' then
  do
    call JSON_initParser
    if RESULT <> 0 then
      cleanup('** JSON Parser instance could not be setup **')
  end
  if g.verbose then
    say 'Invoke Json Parser'
  /**************************************************/
  /* Call the HWTJPARS toolkit api.                 */
  /* Parse scans the input text body and creates an */
  /* internal representation of the JSON data,      */
  /* suitable for search and create operations.     */
  /**************************************************/
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjpars ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "jsonTextBody ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
    do
    call JSON_surfaceDiag 'hwtjpars', RexxRC, ReturnCode
    return fatalError('** hwtjpars failure **')
  end  /* endif hwtjpars failure */
  if g.verbose then
    say 'JSON data parsed successfully'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Procedure: JSON_searchAndDeserializeData                                 */
/*--------------------------------------------------------------------------*/
/* Search for specific values and objects in the parsed response body,      */
/* and deserialize them into the g.resData. stem variable                   */
/*--------------------------------------------------------------------------*/
JSON_searchAndDeserializeData: procedure expose g. (HWT_CONSTANTS)
  parse arg token, vtype
  g.resData. = ''
  g.resData.0 = 0
  /* deserialize all if no specific value requested */
  if token = '' then
  do
    ReturnCode = -1
    DiagArea. = ''
    NewJSONText = ''
    address hwtjson "hwtjesct ",
                    "ReturnCode ",
                    "HWTJ_DECODE ",
                    "g.resBody ",
                    "NewJSONText ",
                    "DiagArea."
    RexxRC = RC
    if JSON_isError(RexxRC,ReturnCode) then
    do
      call JSON_surfaceDiag 'hwtjesct', RexxRC, ReturnCode
      say '** hwtjseri failure **'
    end /* endif hwtjgval failed */
    say "ResponseData:" NewJSONText
  end
  else
  do
    /* Get Value for token from root object */
    g.resData.1 = token
    g.resData.1.val = JSON_findValue(0, token, vtype)
    g.resData.1.typ = vtype
    g.resData.0 = 1
  end
  if datatype(g.resData.0,'W') then
  do i = 1 to g.resData.0
    /* stem.n = name, stem.n.val = value */
    say "ResponseData" i":" g.resData.i":" g.resData.i.val
  end
return  /* end subroutine */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_findValue                                                */
/*--------------------------------------------------------------------------*/
/* Searches the appropriate portion of the parsed JSON data (that           */
/* designated by the objectToSearch argument) for an entry whose            */
/* name matches the designated searchName argument.  Returns a              */
/* value or handle, depending on the expectedType.                          */
/* Valid Types are:                                                         */
/* HWTJ_OBJECT_TYPE  : Object type                                          */
/* HWTJ_ARRAY_TYPE   : Array type                                           */
/* HWTJ_STRING_TYPE  : String type                                          */
/* HWTJ_NUMBER_TYPE  : Value type                                           */
/* HWTJ_BOOLEAN_TYPE : Boolean type                                         */
/* HWTJ_NULL_TYPE    : No type, will return (null)                          */
/* Returns: value or handle as described above, or  a null result           */
/* if no suitable value or handle is found.                                 */
/*--------------------------------------------------------------------------*/
JSON_findValue: procedure expose g. (HWT_CONSTANTS)
  parse arg objectToSearch, searchName, expectedType
  /*********************************************************/
  /* Trying to find a value for a null entry is perhaps a  */
  /* bit nonsensical, but for completeness we include the  */
  /* possibility.  We make an arbitrary choice on what to  */
  /* return, and do this first, to avoid wasted processing */
  /*********************************************************/
  if expectedType == HWTJ_NULL_TYPE then
    return '(null)'
  if g.verbose then
    say "Invoke Json Search for '"searchName"'"
  /********************************************************/
  /* Search the specified object for the specified name.  */
  /* The value 0 is specified (for the "startingHandle")  */
  /* to indicate that the search should start at the      */
  /* beginning of the designated object.                  */
  /********************************************************/
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjsrch ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "HWTJ_SEARCHTYPE_OBJECT ",
                  "searchName ",
                  "objectToSearch ",
                  "0 ",
                  "searchResult ",
                  "DiagArea."
  RexxRC = RC
  /************************************************************/
  /* Differentiate a not found condition from an error, and   */
  /* tolerate the former.  Note the order dependency here,    */
  /* at least as the called routines are currently written.   */
  /************************************************************/
  if JSON_isNotFound(RexxRC,ReturnCode) then
    return '(not found)'
  if JSON_isError(RexxRC,ReturnCode) then
  do
    call JSON_surfaceDiag 'hwtjsrch', RexxRC, ReturnCode
    say '** hwtjsrch failure **'
    return ''
  end /* endif hwtjsrch failed */
  /* Verify the type of the search result   */
  resultType = JSON_getType(searchResult)
  if resultType <> expectedType then
  do
    if g.verbose | g.showInfo then

      say "** Type mismatch for '"searchName"': "|| ,
          'Found' JSON_getTypeName(resultType)', '|| ,
          'Expected' JSON_getTypeName(expectedType)' **'
    return ''
  end /* endif unexpected type */
  /* Return the located object or array, as appropriate */
  if expectedType == HWTJ_OBJECT_TYPE | expectedType == HWTJ_ARRAY_TYPE then
    return searchResult
  /* Return the located string or number, as appropriate */
  if expectedType == HWTJ_STRING_TYPE | expectedType == HWTJ_NUMBER_TYPE then
    return JSON_getValEntry(searchResult)
  /* Return the located boolean value, as appropriate */
  if expectedType == HWTJ_BOOLEAN_TYPE then
    return JSON_getBoolEntry(searchResult)
  if g.verbose then
    say '** No return value found **'
return ''  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getType                                                  */
/*--------------------------------------------------------------------------*/
/* Determine the Json type of the designated search result via the HWTJGJST */
/* toolkit api.                                                             */
/* Returns: Non-negative integral number indicating type if successful,     */
/*  -1 if not.                                                              */
/*--------------------------------------------------------------------------*/
JSON_getType: procedure expose g. (HWT_CONSTANTS)
  parse arg searchResult
  if g.verbose then
    say 'Invoke Json Get Type'
  /* Call the HWTHGJST toolkit api */
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjgjst ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "searchResult ",
                  "resultTypeName ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    call JSON_surfaceDiag 'hwtjgjst', RexxRC, ReturnCode
    return fatalError('** hwtjgjst failure **')
  end /* endif hwtjgjst failure */
  else
  do
    /******************************************************/
    /* Convert the returned type name into its equivalent */
    /* constant, and return that more convenient value.   */
    /* Note that the interpret instruction might more     */
    /* typically be used here, but the goal here is to    */
    /* familiarize the reader with these types.           */
    /******************************************************/
    type = strip(resultTypeName)
    if g.verbose then
      say 'Found type:' type
    if pos(type,'HWTJ_STRING_TYPE HWTJ_NUMBER_TYPE HWTJ_BOOLEAN_TYPE' ,
           'HWTJ_ARRAY_TYPE HWTJ_OBJECT_TYPE HWTJ_NULL_TYPE') > 0 then
      return value(type)
  end
  /* This return should not occur, in practice.  */
return fatalError('Unsupported Type ('type') from hwtjgjst')

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getTypeName                                              */
/*--------------------------------------------------------------------------*/
/* Helper function to determine the Json type Name from the provided const. */
/* Returns: Name of the constant, or Unknown type                           */
/*--------------------------------------------------------------------------*/
JSON_getTypeName: procedure expose g. (HWT_CONSTANTS)
  parse arg typeVal
  select
    when typeVal = HWTJ_STRING_TYPE then return 'HWTJ_STRING_TYPE'
    when typeVal = HWTJ_NUMBER_TYPE then return 'HWTJ_NUMBER_TYPE'
    when typeVal = HWTJ_BOOLEAN_TYPE then return 'HWTJ_BOOLEAN_TYPE'
    when typeVal = HWTJ_ARRAY_TYPE then return 'HWTJ_ARRAY_TYPE'
    when typeVal = HWTJ_OBJECT_TYPE then return 'HWTJ_OBJECT_TYPE'
    when typeVal = HWTJ_NULL_TYPE then return 'HWTJ_NULL_TYPE'
    otherwise return 'Unknown_Type'
  end
  /* This return should not occur, in practice.  */
return ''

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getNumElem                                               */
/*--------------------------------------------------------------------------*/
/* Determine the number of elments contained in the input                   */
/* JSON handle via the HWTJGNUE service                                     */
/* Returns: Non-negative number indicating number if successful,            */
/*  -1 if not.                                                              */
/*--------------------------------------------------------------------------*/
JSON_getNumElem:
  parse arg inputHandle
  /* Call the HWTJGNUE toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  objDim = 0
  address hwtjson "hwtjgnue ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "inputHandle ",
                  "dimOut ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    call JSON_surfaceDiag 'hwtjgnue', RexxRC, ReturnCode
    return fatalError('** hwtjgnue failure **')
  end /* endif hwtjgnue failure */
  objDim = strip(dimOut,'L',0)
  if objDim == '' then
    return 0
return objDim  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getObjEntry                                              */
/*--------------------------------------------------------------------------*/
/* Return a handle to the designated entry of the object designated by the  */
/* input handle, obtained via the HWTJGOEN toolkit api. The object name is  */
/* appended to the 4 byte handle.                                           */
/* Returns: 4 byte string with handle plus optional name                    */
/* Use the parse val method to separate handle and name, eg:                */
/* parse value JSON_getObjEntry(objHandle,Idx) with handle 5 name           */
/*--------------------------------------------------------------------------*/
JSON_getObjEntry: procedure expose g.
  parse arg objHandle, entryIdx
  if g.verbose then
    say 'Getting object entry' entryIdx
  /* Call the HWTJGOEN toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  entryName = ''
  address hwtjson "hwtjgoen ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "objHandle ",
                  "entryIdx ",
                  "entryName ",
                  "handleOut ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    /* surface error and exit */
    call JSON_surfaceDiag 'hwtjgoen', RexxRC, ReturnCode
    cleanup('** Failure in hwtjgoen to get object entry **')
  end /* endif hwtjgoen failure */
return handleOut||entryName  /* return fix 4 byte handle plus name */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getArrEntry                                              */
/*--------------------------------------------------------------------------*/
/* Return a handle to the designated entry of the array designated by the   */
/* input handle, obtained via the HWTJGAEN toolkit api.                     */
/* Returns: Output handle from toolkit api                                  */
/*--------------------------------------------------------------------------*/
JSON_getArrEntry: procedure expose g.
  parse arg arrayHandle, whichEntry
  handleOut = ''
  if g.verbose then
    say 'Getting array entry'
  /* Call the HWTJGAEN toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjgaen ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "arrayHandle ",
                  "whichEntry ",
                  "handleOut ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    /* surface error and exit */
    call JSON_surfaceDiag 'hwtjgaen', RexxRC, ReturnCode
    cleanup('** Failure in hwtjgaen to get array entry **')
  end /* endif hwtjgaen failure */
return handleOut  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getValEntry                                              */
/*--------------------------------------------------------------------------*/
/* Return value of a string or number handle                                */
/*--------------------------------------------------------------------------*/
JSON_getValEntry: procedure expose g.
  parse arg vHandle
  val = ''
  if g.verbose then
    say 'Getting value entry'
  /* Call the HWTJGVAL toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjgval ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "vHandle ",
                  "val ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    /* surface error and exit */
    call JSON_surfaceDiag 'hwtjgval', RexxRC, ReturnCode
    cleanup('** Failure in hwtjgval to get value entry **')
  end /* endif hwtjgval failed */
return val /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_getBoolEntry                                             */
/*--------------------------------------------------------------------------*/
/* Return the boolean value of a handle                                     */
/*--------------------------------------------------------------------------*/
JSON_getBoolEntry: procedure expose g.
  parse arg vHandle
  val = ''
  if g.verbose then
    say 'Getting boolean entry'
  /* Call the HWTJGBOV toolkit api.  */
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjgbov ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "vHandle ",
                  "val ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    /* surface error and exit */
    call JSON_surfaceDiag 'hwtjgbov', RexxRC, ReturnCode
    cleanup('** Failure in hwtjgbov to get boolean entry **')
  end /* endif hwtjgbov failed */
return val /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_termParser                                               */
/*--------------------------------------------------------------------------*/
/* Cleans up parser resources and invalidates the parser instance handle,   */
/* via call to the HWTJTERM toolkit api.                                    */
/* Note that as the REXX environment is single-threaded, no consideration   */
/* of any "busy" outcome from the api is done (as it would be in other      */
/* language environments).                                                  */
/* Returns: 0 if successful, -1 if not.                                     */
/*--------------------------------------------------------------------------*/
JSON_termParser:
  if g.verbose then
    say 'Terminating Json Parser (hwtjterm)'
  /* Call the HWTJTERM toolkit api  */
  ReturnCode = -1
  DiagArea. = ''
  address hwtjson "hwtjterm ",
                  "ReturnCode ",
                  "g.pHandle ",
                  "DiagArea."
  RexxRC = RC
  if JSON_isError(RexxRC,ReturnCode) then
  do
    call JSON_surfaceDiag 'hwtjterm', RexxRC, ReturnCode
    return fatalError('** hwtjterm failure **')
  end /* endif hwtjterm failure */
  if g.verbose then
    say 'Json Parser terminated'
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_isNotFound                                               */
/*--------------------------------------------------------------------------*/
/* Check the input processing codes.                                        */
/* Note that if the input RexxRC is nonzero, then the toolkit return code   */
/* is moot (the toolkit function was likely not even invoked). If the       */
/* toolkit return code is relevant, check it against the specific return    */
/* code for a "not found" condition.                                        */
/* Returns: -1 if a HWTJ_JSRCH_SRCHSTR_NOT_FOUND condition is indicated,    */
/* 0 otherwise.                                                             */
/*--------------------------------------------------------------------------*/
JSON_isNotFound:
  parse arg RexxRC, ToolkitRC
  if RexxRC <> 0 then
    return 0
  ToolkitRC = strip(ToolkitRC,'L',0)
  if ToolkitRC == HWTJ_JSRCH_SRCHSTR_NOT_FOUND then
    return 1
return 0  /* end function */

/*--------------------------------------------------------------------------*/
/* Function:  JSON_isError                                                  */
/*--------------------------------------------------------------------------*/
/* Check the input processing codes.                                        */
/* Note that if the input RexxRC is nonzero, then the toolkit return code   */
/* is moot (the toolkit function was likely not even invoked). If the       */
/* toolkit return code is relevant, check it against the set of  HWTJ_xx  */
/* return codes for evidence of error. This set is ordered:                 */
/* HWTJ_OK < HWTJ_WARNING < ...                                             */
/* with remaining codes indicating error, so we may check via single        */
/* inequality.                                                              */
/* Returns: -1 if any toolkit error is indicated, 0 otherwise               */
/*--------------------------------------------------------------------------*/
JSON_isError:
  parse arg RexxRC, ToolkitRC
  if RexxRC <> 0 then
    return 1
  ToolkitRC = strip(ToolkitRC,'L',0)
  /* Toolkit returns integer while constants are hex */
  if datatype(ToolkitRC,'W') then
    if ToolkitRC > 0 then ToolkitRC = d2x(ToolkitRC)
  if ToolkitRC == '' then
    return 0
  if ToolkitRC <= HWTJ_WARNING then
    return 0
return 1 /* end function */

/*--------------------------------------------------------------------------*/
/* Procedure: JSON_surfaceDiag                                              */
/*--------------------------------------------------------------------------*/
/* Surface input error information.                                         */
/* Note that when the RexxRC is nonzero, the ToolkitRC and DiagArea         */
/* content are moot and are suppressed (so as to not mislead).              */
/*--------------------------------------------------------------------------*/
JSON_surfaceDiag: procedure expose DiagArea. g.
  parse arg who, rexxRC, ToolkitRC
  say
  say '*JSON-ERROR* ('who') at time:' Time()
  /* Toolkit returns integer while constants are hex */
  if datatype(ToolkitRC,'W') then
    if ToolkitRC > 0 then ToolkitRC = d2x(ToolkitRC)
  say 'Rexx RC: 'RexxRC', Toolkit ReturnCode:' ToolkitRC
  if RexxRC == 0 then
  do
    say 'DiagArea.ReasonCode:' DiagArea.HWTJ_ReasonCode
    say 'DiagArea.ReasonDesc:' DiagArea.HWTJ_ReasonDesc
  end
  say
return  /* end procedure */


/*--------------------------------------------------------------------------*/
/*                     Common program related functions                     */
/*--------------------------------------------------------------------------*/
/* These are helper functions used by the program                           */
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* Procedure: updtCredentials                                               */
/*--------------------------------------------------------------------------*/
/* Obtain user credentials for CSM Rest API. Get them from a DS or file.    */
/* If the specified DS or file does not exist, allocate a new one.          */
/* If no credentials found and rexx is executed in foreground, prompt       */
/* user for credentials and save them with encoding.                        */
/* The encoding will be via a private key that shuffles and translates all  */
/* chars. The private key will be loaded once from the specified private    */
/* key file. If no private key found, a new one will be created and saved.  */
/* If a request token was received, it will also be saved in the credential */
/* file, so it can be reused on subsequent requests.                        */
/*--------------------------------------------------------------------------*/
updtCredentials: procedure expose g.
  parse arg mydsn, clear
  if clear <> '' then
    clear = 1
  else
    clear = 0

  /* Try to read private key for cipher if not done before */
  if g.rPriKey = '' & clear = 0 then
  do
    if g.verbose then
      say "Reading private key from '"g.EncrFile"'"
    /* Allocate (new or existing) private key file */
    if pos('/',g.EncrFile) > 0 then
    do
      /* OMVS filename defined */
      if allocateDD(g.encrDD,g.EncrFile,"PATHDISP(KEEP,DELETE) FILEDATA"|| ,
        "(TEXT) PATHOPTS(ORDWR,OCREAT) PATHMODE(SIRUSR,SIWUSR)") <> 0 then
      do
        return fatalError('** File' g.EncrFile 'could not be allocated **')
      end
    end
    else
    do
      /* member or full DSN defined */
      if allocateDD(g.encrDD,g.EncrFile,"UNIT(3390) SPACE(1,1) TRACKS "|| ,
        "LRECL(80) RECFM(F,B)") <> 0 then
      do
        return fatalError("** '"g.EncrFile"' could not be allocated **")
      end
    end

    /* Read private key */
    address MVS "EXECIO * DISKR" g.encrDD "(OPEN STEM mydata. FINIS)"
    x = bpxwdyn("FREE FI('"g.encrDD"')")
    prikey = ''
    if datatype(mydata.0,'W') then
    do i = 1 to mydata.0
      prikey = prikey||strip(mydata.i)
    end
    if datatype(prikey,'X') & prikey <> '' then
      g.rPriKey = x2c(prikey)
  end

  /* Check if private key found, create new and save if not */
  if g.rPriKey = '' & clear = 0 then
  do
    /* Generate new random priv key by shuffling chars from public key */
    if g.verbose then
      say "No private key found, creating new key..."
    g.rPriKey = cipher(,"KEYGEN")
    /* Save private key in file */
    if g.verbose then
      say "Saving private key to '"g.EncrFile"'"
    if pos('/',g.EncrFile) > 0 then
    do
      /* re-allocate OMVS file in write mode only to reset file pointer */
      if allocateDD(g.encrDD,g.EncrFile,"FILEDATA(TEXT) "|| ,
        "PATHOPTS(OWRONLY,OTRUNC)") <> 0 then
      do
        return fatalError('** File' g.EncrFile 'could not be allocated **')
      end
    end
    else
    do
      /* member or full DSN defined */
      if allocateDD(g.encrDD,g.EncrFile,"") <> 0 then
      do
        return fatalError("** '"g.EncrFile"' could not be allocated **")
      end
    end
    /* convert key to hex string for saving */
    mydata.0 = 0
    prikey = c2x(g.rPriKey)
    do i = 1 by 1 while prikey <> ''
      /* save private key in hex in chunks of 80 chars */
      mydata.i = strip(left(prikey,80))
      mydata.0 = i
      prikey = strip(substr(prikey,81))
    end
    address MVS "EXECIO" mydata.0 "DISKW" g.encrDD "(OPEN STEM mydata. FINIS)"
    myrc = RC
    x = bpxwdyn("FREE FI('"g.encrDD"')")
    if myrc = 0 then
    do
      if g.Verbose then
        say "Saved private key in '"g.EncrFile"'"
    end
    else
      return fatalError("** Could not save private key to '"g.EncrFile,
             ||"', RC:" myrc)
  end

  /* Allocate credentials file */
  if g.verbose then
    say "Accessing server credentials from '"mydsn"'"
  if pos('/',mydsn) > 0 then
  do
    /* OMVS filename defined */
    if allocateDD(g.authDD,mydsn,"PATHDISP(KEEP,DELETE) FILEDATA(TEXT) "|| ,
      "PATHOPTS(ORDWR,OCREAT) PATHMODE(SIRUSR,SIWUSR) REUSE") <> 0 then
    do
      return fatalError('** File' mydsn 'could not be allocated **')
    end
  end
  else
  do
    /* member or full DSN defined */
    if allocateDD(g.authDD,mydsn,"UNIT(3390) SPACE(1,1) TRACKS "|| ,
      "LRECL(80) RECFM(F,B) REUSE") <> 0 then
    do
      return fatalError("** '"mydsn"' could not be allocated **")
    end
  end

  /* Clear file if requested and return */
  if clear then
  do
    if g.verbose then
      say "Clearing server credentials in '"mydsn"'"
    /* re-allocate OMVS file in write trunc mode only to reset file pointer */
    if pos('/',mydsn) > 0 then
    do
      x = bpxwdyn("FREE FI("g.authDD")")
      if allocateDD(g.authDD,mydsn,"FILEDATA(TEXT) "|| ,
        "PATHOPTS(OWRONLY,OTRUNC)") <> 0 then
      do
        return fatalError('** File' mydsn 'could not be allocated **')
      end
    end
    mydata.0 = 3
    mydata.1 = 'username='
    mydata.2 = 'password='
    mydata.3 = 'token='
    address MVS "EXECIO" mydata.0 "DISKW" g.authDD "(OPEN STEM mydata. FINIS)"
    x = bpxwdyn("FREE FI("g.authDD")")
    return 0
  end

  /* Read credentials member if credentials still unknown */
  if g.rUsername = '' | g.rPassword = '' then
  do
    if g.verbose then
      say "Reading server credentials from '"mydsn"'"
    address MVS "EXECIO * DISKR" g.authDD "(OPEN STEM mydata. FINIS)"
    if datatype(mydata.0,'W') then
    do i = 1 to mydata.0
      parse var mydata.i parm "=" val .
      /* Decrypt parameters */
      if left(val,4) = 'XOR:' then
        val = cipher(substr(val,5),'DECODE')
      if parm = 'username' then
        g.rUsername = val
      else if parm = 'password' then
        g.rPassword = val
      else if parm = 'token' then
        g.rToken = val
    end
  end

  /* Query credentials from user if not set */
  if g.rUsername = "" | g.rPassword = "" then
  do
    /* Clear token of previous user */
    g.rToken = ''
    if g.ShowInfo | g.verbose then
      say "No valid credentials found in '"mydsn"'"
    /* Pull credentials from user when running in foreground */
    if g.adspace='OMVS' then
    do
      /* if a shell environment, use getpass to hide input */
      say 'Enter credentials for server:' g.cUri
      say 'Enter CSM Username:'
      g.rUsername = linein(,,1)
      g.rPassword = getpass('Enter User Password:')
    end
    else if g.adspace='ISPF' then
    do
      if left(sysvar('SYSENV'),4) = "FORE" then
        call getISPFcred
    end
    else if g.adspace='TSO/E' then
    do
      /* Running in TSO shell or as job */
      if left(sysvar('SYSENV'),4) = "FORE" then
      do
        /* ATTN: Pulling password with echo if running in foreground */
        say 'Enter credentials for server:' g.cUri
        say 'Enter CSM Username:'
        parse pull g.rUsername
        say 'Enter User Password:'
        parse pull g.rPassword
      end
    end
    else
    do
      /* ATTN: Unknown environment will use prompt with ECHO */
      say 'Running on Host:' g.host ' Env:' g.environ ' AdSpace:' g.adspace
      say 'Enter credentials for server:' g.cUri
      say 'Enter CSM Username:'
      parse pull g.rUsername
      say 'Enter User Password:'
      parse pull g.rPassword
    end
  end
  /* Exit if username or password still empty */
  if g.rUsername = "" | g.rPassword = "" then
  do
    /* clear credentials file with new template */
    if g.verbose then
      say "Reallocating '"mydsn"' to clear credentials"
    x = bpxwdyn("FREE FI("g.authDD")")
    x = updtCredentials(mydsn,'CLEAR')
    if g.verbose then
      say 'Clearing credential file RC:' x
    cleanup('** Failed to get credentials| Execute in foreground' ,
            'to pull credentials from user, or enter them into' mydsn ,
            'for encryption during next execution. **')
  end

  /* Write encrypted credentials and token back to member */
  mydata.0 = 3
  mydata.1 = 'username=XOR:'cipher(g.rUsername,'ENCODE')
  mydata.2 = 'password=XOR:'cipher(g.rPassword,'ENCODE')
  if g.rToken <> '' then
    mydata.3 = 'token=XOR:'cipher(g.rToken,'ENCODE')
  else
    mydata.3 = 'token='
  /* re-allocate OMVS file in write mode only to reset file pointer */
  if pos('/',mydsn) > 0 then
  do
    x = bpxwdyn("FREE FI("g.authDD")")
    if allocateDD(g.authDD,mydsn,"FILEDATA(TEXT) "|| ,
      "PATHOPTS(OWRONLY,OTRUNC)") <> 0 then
    do
      return fatalError('** File' mydsn 'could not be allocated **')
    end
  end
  address MVS "EXECIO" mydata.0 "DISKW" g.authDD "(OPEN STEM mydata. FINIS)"
  if RC = 0 then
  do
    if g.Verbose then
      say "Saved encrypted credentials in '"mydsn"'"
  end
  else
    say "** Could not save encrypted credentials to '"mydsn"', RC:" RC
  x = bpxwdyn("FREE FI("g.authDD")")
  if g.rUsername = "" | g.rPassword = "" then
    return fatalError('** Missing Username or Password **')
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: allocateDD                                                    */
/*--------------------------------------------------------------------------*/
/* Allocate existing DSN or file or create new if not existing.             */
/* The specified type will be recognized from the name, allocation options  */
/* will be used when a new file must be allocated.                          */
/* The file will be allocated under the specified DD name                   */
/*--------------------------------------------------------------------------*/
allocateDD: procedure expose g.
  parse arg mydd, mydsn, allocopt
  isFile = 0 /* Flag to indicate USS filename */
  isLib  = 0 /* Flag to indicate Library */
  lookmbr = 0 /* Flag to indicate whether member to be looked up */
  /* disable  messages */
  if pos('/',mydsn) > 0 then
  do
    isFile = 1
    isLib = 0
    mymbr = ""
  end
  else
  do
    /* Determine DSN of rexx and use the same if only member provided */
    if g.rexxdsn = '?' then g.rexxdsn = ''
    if g.rexxdsn = '' then g.rexxdsn = getAlocFile('SYSEXEC')
    /* Extract optional member */
    parse upper var mydsn mydsn '(' mymbr ')' .
    mydsn = strip(mydsn)
    if mymbr <> '' then
    do
      mymbr = '('mymbr')'
      isLib = 1
      lookmbr = 1
    end
    /* default mydsn to rexx DSN if only member provided */
    if mydsn = '' & g.rexxdsn <> '' & pos('/',g.rexxdsn) = 0 then
      mydsn = g.rexxdsn
    mydsn = strip(mydsn,,"'")
  end

  /* check if DS name found or specified */
  if mydsn <> '' then
  do
    /* if no OMVS file, ensure DSN and optional member is created first */
    if isFile = 0 then
    do
      if bpxwdyn("ALLOC FI("mydd") DA('"mydsn"') SHR REUSE"),
         <> 0 then
      do
        /* Create new DSN */
        if g.verbose then
          say "Creating new dataset" mydsn
        /* Check if DSN Type specified and use proper alloc option */
        if pos('DSNTYPE(',translate(allocopt)) = 0 then
        do
          if isLib then
            allocopt = "DSNTYPE(LIBRARY) DSORG(PO)" allocopt
          else
            allocopt = "DSNTYPE(BASIC) DSORG(PS)" allocopt
        end
        x = bpxwdyn("ALLOC FI("mydd") DA('"mydsn"') NEW CATALOG REUSE",
            allocopt)
        if x <> 0 then
        do
          return fatalError('New dataset' mydsn 'could not be allocated,' ,
                            'RC:' x " OPTIONS:" allocopt)
        end
        lookmbr = 0  /* indicate that member does not exist */
      end
      /* Get DSORG of allocated DSN and FREE again */
      y = bpxwdyn("INFO FI("mydd") INRTORG(dsorg)")
      y = bpxwdyn("FREE FI("mydd")")
      /* Create new member if required */
      if isLib then
      do
        if g.verbose then
          say "Checking if member" mymbr "exists"
        /* Check if existing DSN is library to allow member creation */
        if left(strip(dsorg),2) <> 'PO' then
          return fatalError("** Existing dataset '"mydsn"' is no library **")
        /* Check if member exists */
        if lookmbr then
        do
          name = ""
          /* Reallocate as sequential DS to read directory */
          if bpxwdyn("ALLOC FI("mydd") DA('"mydsn"') SHR REUSE MSG(2)",
            "RECFM(F) DSORG(PS) LRECL(256) BLKSIZE(256)") = 0 then
          do
            looking = 1
            do while looking
              address MVS "EXECIO 1 DISKR" mydd "(STEM dir."
              if RC <> 0 | dir.0 = 0 then leave  /* empty dataset */
              used = c2d(substr(dir.1,1,2)) /* used bytes */
              i = 3  /* first entry starts in third byte */
              do while i < used
                name = strip(substr(dir.1,i,8))
                if substr(dir.1,i,8) = 'FFFFFFFFFFFFFFFF'x | ,
                  '('name')' = mymbr then
                do
                  looking = 0
                  leave
                end
                i = i + 8 + 3 /* skip name, skip offset */
                /* get data len */
                len = c2d(bitand(substr(dir.1,i,1),'1F'x)) * 2
                i = i + 1 /* skip info byte */
                i = i + len /* skip user data */
              end
            end
            /* Close dataset */
            address MVS "EXECIO 0 DISKR" mydd "(FINIS)"
            x = bpxwdyn("FREE FI("mydd")")
          end
          lookmbr = "("name")" = mymbr /* indicate member exists */
        end
        if g.verbose then
        do
          if lookmbr then
            say "Found member" mymbr
          else
            say "Member" mymbr "not found"
        end

        /* Ensure empty member is created if not found to read from it */
        if lookmbr = 0 then
        do
          /* Member allocation is also OK if not existing */
          if bpxwdyn("ALLOC FI("mydd") DA('"mydsn||mymbr"') SHR REUSE") = 0,
          then do
            /* Write empty record into member to create it */
            mydata.0 = 1
            mydata.1 = ''
            address MVS "EXECIO" mydata.0 "DISKW" mydd ,
                        "(STEM mydata. FINIS)"
            if RC <> 0 then
            do
              y = bpxwdyn("FREE DA('"mydsn||mymbr"')")
              return fatalError("Member '"mydsn||mymbr"' not created")
            end
            else if g.verbose then
              say "Created new member '"mydsn||mymbr"'"
          end
          y = bpxwdyn("FREE DA('"mydsn||mymbr"')")
        end
      end
    end

    /* allocate the DSN or OMVS file */
    if isFile then
    do
      myRC = bpxwdyn("ALLOC FI("mydd") PATH('"mydsn"')" allocopt)
      if myRC = 0 then
      do
        /* check path is truely a file */
        filetype = checkUSSFile(mydsn)
        if filetype <> "FILE" then
          myRC = "Invalid type ("filetype")"
      end
    end
    else
    do
      myRC = bpxwdyn("ALLOC FI("mydd") DA('"mydsn||mymbr"') SHR REUSE")
    end
  end
  else
    myRC = "DSN/File not defined"  /* Dataset name not found/specified */
  if myRC <> 0 then
  do
    y = bpxwdyn("FREE FI('"mydd"')")
    return fatalError("** '"mydsn||mymbr"' could not be allocated," ,
                      "RC:" myRC)
  end
  else if g.verbose then
    say "Allocated '"mydsn||mymbr"' to DDN" mydd
return 0

/*--------------------------------------------------------------------------*/
/* Procedure: getAlocFile                                                   */
/*--------------------------------------------------------------------------*/
/* Get allocated DSN or path from provided DD name                          */
/* Returns: Null string if DD name is not allocated, Filename/DSN otherwise */
/*--------------------------------------------------------------------------*/
getAlocFile: procedure
   parse arg ddname
   fname = ''
   /* BPXWDYN INFO call returns only information for allocated files */
   if bpxwdyn("INFO FI("ddname") INRTDSN(dsn) INRTPATH(path)") = 0 then
   do
     /* path contains 00 bytes if not set */
     path = strip(path,,'00'x)
     if dsn <> '' then fname = dsn
     /* DSN name may refer to used path, overwrite if path is not null */
     if path <> '' then fname = path
   end
return fname

/*--------------------------------------------------------------------------*/
/* Procedure: checkUSSFile                                                  */
/*--------------------------------------------------------------------------*/
/* Verify the state of the given USS path/filename                          */
/* Returns Type as string.                                                  */
/*--------------------------------------------------------------------------*/
checkUSSFile: procedure
  parse arg path
  if syscalls('ON') <> 0 then
    return 'INVALID'
  /* Use USS stat function */
  address SYSCALL 'stat' path 'stat.'
  /* Error processing */
  if RETVAL <> 0 | ERRNO <> 0 | ERRNOJR <> 0 then
  do
    /* Translate the cryptic USS errors to cryptic English descriptions */
    if g.verbose then
    do
      say path
      address SYSCALL 'strerror' ERRNO ERRNOJR 'err.'
      say err.SE_ERRNO
      parse var err.SE_REASON . '15'x errmsg
      say errmsg
      say err.SE_ACTION
    end
    return 'NOT FOUND'
  end
  /* Return the valid conditions */
  select
    when stat.ST_TYPE = S_ISREG then return 'FILE'
    when stat.ST_TYPE = S_ISDIR then return 'DIRECTORY'
    when stat.ST_TYPE = S_ISSYM then return 'SYMLINK'
    when stat.ST_TYPE = S_ISCHR then return 'CHAR'
    when stat.ST_TYPE = S_ISFIFO then return 'PIPE'
    otherwise return 'INVALID'
  end
return ''

/*--------------------------------------------------------------------------*/
/* Procedure: getISPFcred                                                   */
/*--------------------------------------------------------------------------*/
/* Create or use existing ISPF panel mbr to prompt credentials without echo */
/*--------------------------------------------------------------------------*/
getISPFcred: procedure expose g.
  /* Check and optionally create ISPF credentials panel member */
  /* extract dataset and member for ISPF panel */
  parse var g.IPanDsn mydsn '(' mymbr ')' .
  if mymbr = '' then
    return fatalError('** ISPF Panel member not defined **')
  /* Allocate ISPF panel member */
  if allocateDD(g.IPanDD,g.IPanDsn,"UNIT(3390) SPACE(1,1) TRACKS "|| ,
    "LRECL(80) RECFM(F,B)") <> 0 then
    return fatalError('** ISPF Panel member' mymbr 'could not be allocated **')
  /* Refresh DSN & Member from allocated file */
  if mydsn = "" then
    mydsn = getAlocFile(g.IPanDD)
  if mydsn = "" then
    return fatalError('** ISPF Panel DS name could not be identified **')
  /* Check if DD is empty */
  mydata.0 = 0
  address MVS "EXECIO * DISKR" g.IPanDD "(STEM mydata. FINIS)"
  if mydata.0 < 2 then
  do
    /* Dynamically create ISPF Panel member */
    mydata.1 =")PANEL"
    mydata.2 =")ATTR"
    mydata.3 =" TYPE(INPUT) INTENS(HIGH) COLOR(BLUE) CAPS(OFF) PAD(_)"
    mydata.4 ="* TYPE(INPUT) INTENS(NON) PAD(_) CAPS(OFF) HILITE(USCORE)"
    mydata.5 ="| TYPE(TEXT) COLOR(GREEN) SKIP(ON)"
    mydata.6 ="_ TYPE(TEXT) INTENS(HIGH) COLOR(RED) SKIP(ON)"
    mydata.7 ="# TYPE(TEXT) INTENS(HIGH) COLOR(TURQ) SKIP(ON)"
    mydata.8 =" TYPE(TEXT) INTENS(HIGH) COLOR(YELLOW) SKIP(ON)"
    mydata.9 =")BODY WINDOW(48,16)"
    mydata.10="|"
    mydata.11="|"
    mydata.12="# ENTER SERVER CREDENTIALS FOR CSM REST API"
    mydata.13="#-------------------------------------------"
    mydata.14="|"
    mydata.15="|&SERVER"
    mydata.16="|"
    mydata.17="| ENTER USERNAME:UNAME               |"
    mydata.18="| ENTER PASSWORD:*PWD                 |"
    mydata.19="|"
    mydata.20="|"
    mydata.21="|_&PMSG"
    mydata.22="|"
    mydata.23=")INIT"
    mydata.24=".CURSOR=&CSR"
    mydata.25=")REINIT"
    mydata.26="REFRESH(*)"
    mydata.27=")PROC"
    mydata.28="&PFPRSD = .PFKEY"
    mydata.29="&RESP = .RESP"
    mydata.30=")END"
    mydata.0=30
    address MVS "EXECIO" mydata.0 "DISKW" g.IPanDD "(STEM mydata. FINIS)"
  end
  /* Free allocated member again */
  y = bpxwdyn("FREE FI('"mydd"')")

  /* Prepare ISPF panel */
  ADDRESS ISPEXEC
  SERVER= g.cUri
  UNAME = g.rUsername
  PWD   = ""
  PMSG  = "SAVED CREDENTIALS NOT FOUND, PLEASE ENTER"
  CSR   = "UNAME"
  /* Dynamically define Panel DS */
  "LIBDEF ISPPLIB DATASET ID('"mydsn"') UNCOND"
  /* show as popup panel */
  "ADDPOP"
  do forever
    /* Display the ISPF panel to enter credentials */
    "DISPLAY PANEL("mymbr")"
    if RESP = 'ENTER' then
    do
      /* Leave if Credentials provided */
      if UNAME <> '' & PWD <> '' then
        leave
      /* Toggle input field on ENTER */
      if CSR = 'UNAME' & UNAME <> '' then
        CSR = 'PWD'
      if CSR = 'PWD' & PWD <> '' then
        CSR = 'UNAME'
      /* Clear any message */
      PMSG = " "
    end
    else if RESP = 'END' then
    do
      /* Abort if Exit pressed twice while input missing */
      if word(PMSG,1) = "MISSING" then
        leave
      /* Check if both fields filled */
      if (UNAME='' | PWD = '') & word(PMSG,1) <> "MISSING" then
        PMSG = "MISSING INPUT| (HIT EXIT AGAIN TO ABORT)"
      else
      do
        /* Leave if Credentials provided */
        PMSG = " "
        leave
      end
    end
    else if RC > 0 Then Leave  /* PF3 = RC 8 */
  end
  /* Remove defined Panel DS */
  "REMPOP"
  "LIBDEF ISPPLIB"
  address TSO
  g.rUsername = UNAME
  g.rPassword = PWD
return

/*--------------------------------------------------------------------------*/
/* Procedure: cipher                                                        */
/*--------------------------------------------------------------------------*/
/* Encode or decode the given string (default is encode)                    */
/* If KEYGEN is specified, a new private key is returned.                   */
/* Returns: Converted string or private key, otherwise null string          */
/*--------------------------------------------------------------------------*/
cipher: procedure expose g.
  parse arg str, what
  upper what
  retstr = ''

  /* Define the public key with all possible chars and letters expected     */
  /* for credentials. Ensure each char is used only ONCE.                   */
  /* A change in the public key requires to regenerate the private key      */
  pubkey = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'||,
           '1234567890|$%&/()='

  /* check what to do */
  if what = 'KEYGEN' then
  do
  /* The private key will be generated from the public key by shuffling the */
  /* order of each char. To ensure decryption will work, each char in key   */
  /* must be unique. The key will be saved as hex string to specified file  */
    temp = pubkey
    prikey = ''
    c = 0
    do while temp <> ''
      /* try shuffle char up to 3 times */
      c = c + 1
      do i = 1 to 3
        idx = random(1,length(temp)) /* Pick random position from remaining */
        if substr(temp,idx,1) <> substr(pubkey,c,1) then leave
      end
      prikey = prikey || substr(temp,idx,1)
      temp = delstr(temp,idx,1)    /* Remove used char from remaining */
    end
    return prikey
  end
  else if what = 'ENCODE' then
    decode = 0
  else
    decode = 1

  prikey = g.rPriKey
  if prikey <> '' then
  do i=1 to length(str)
    if decode then
      retstr = retstr||translate(substr(str,i,1),pubkey,prikey)
    else
      retstr = retstr||translate(substr(str,i,1),prikey,pubkey)
  end
return retstr  /* end procedure */

/*--------------------------------------------------------------------------*/
/* Function: ConvBlanks                                                     */
/*--------------------------------------------------------------------------*/
/* Converts blanks to %20 and vice versa for parms to be used in requests.  */
/* Returns converted string                                                 */
/*--------------------------------------------------------------------------*/
ConvBlanks: procedure
  parse arg str
  newstr = ''
  if pos('%20',str) > 0 then
  do while str <> ''
    /* Convert all back to blanks */
    parse var str pre '%20' str
    newstr = newstr||pre
    if str <> '' then newstr = newstr' '
  end
  else if pos(' ',str) > 0 then
  do while str <> ''
    /* Convert all blanks to %20 */
    parse var str pre str
    newstr = newstr||pre
    if str <> '' then newstr = newstr'%20'
  end
  else
    newstr = str
return newstr

/*--------------------------------------------------------------------------*/
/* Function: ConvUnixTime                                                   */
/*--------------------------------------------------------------------------*/
/* Converts Unix Epoche timestamp to YYYY/MM/DD HH:MM:SS                    */
/* Unix time is the number of seconds since midnight 1-1-1970               */
/* CSM timestamps are Unix UTC timestamps in milliseconds                   */
/* Timezone adjustments are considered if global g.tTimeOff is set.         */
/* Returns converted string (or input string if invalid Unix time stamp)    */
/*--------------------------------------------------------------------------*/
ConvUnixTime: procedure expose g.
  parse arg uxtime
  numeric digits 31
  if datatype(uxtime,'W') = 0 then
  do
    numeric digits
    return uxtime
  end
  /* consider adjustments, timezone or no conversion if global not set */
  if g.tTimeOff = '' then
  do
    numeric digits
    return uxtime
  end
  else if datatype(g.tTOsec,'W') = 0 then
  do
    /* initialize offset in seconds once or reset globals if invalid */
    invalid = 0
    parse var g.tTimeOff hour ':' minute .
    if datatype(hour,'W') = 0 | datatype(minute,'W') = 0 then
      invalid = 1
    else if minute > 60 | minute < 0 then  /* negative hours are valid */
      invalid = 1
    if invalid then
    do
      /* clear global to avoid another validation */
      g.tTOsec = ''
      g.tTimeOff = ''
      numeric digits
      return uxtime
    end
    /* set global offset in seconds */
    g.tTOsec = hour * 3600 + minute * 60
  end
  /* Adjust CSM timestamp in ms with offset */
  uxtime = (uxtime % 1000) + g.tTOsec
  /* convert date */
  days = uxtime % (3600 * 24)    /* full days of unix date */
  rexbase = date('B','19700101','S')+days /* full days from rexx base */
  if length(rexbase) > 6 then           /* max 6 digit days base coversion */
  do
    numeric digits
    return uxtime
  end
  newdate = date('O',rexbase,'B')       /* convert base days to yy/mm/dd */
  /* convert time */
  rest = uxtime // (3600 * 24)          /* remaining seconds */
  hh = right(rest % 3600,2,'0')
  rest = rest // 3600
  mm = right(rest % 60,2,'0')
  ss = right(rest // 60,2,'0')
  numeric digits
return newdate hh':'mm':'ss

/*--------------------------------------------------------------------------*/
/* Function: TimeOffset                                                     */
/*--------------------------------------------------------------------------*/
/* Get the local time offset from GMT in mm:ss                              */
/*--------------------------------------------------------------------------*/
TimeOffset: procedure
  numeric digits 21
  /* Get current CVTLDTO (Local Date Time Offset in STCK format)) */
  cvt     = c2d(storage(d2x(16),4))
  cvttz   = c2d(storage(d2x(cvt + 304),4))
  cvtext2 = c2d(storage(d2x(cvt + 328),4))
  cvtldto = c2d(storage(d2x(cvtext2 + 56),8),8)
  /* Calc the current offset in hours and minutes (work with absolute) */
  absldto = abs(cvtldto)
  hours   = absldto % x2d('D693A400000')
  minutes = (absldto % x2d('3938700000')) // 60
  offset  = right(hours,2,'0')':'right(minutes,2,'0')
  if cvtldto < 0 then
    offset = "-"offset
  numeric digits
return offset

/*--------------------------------------------------------------------------*/
/* Function: fatalError                                                     */
/*--------------------------------------------------------------------------*/
/* Surfaces the input message, and returns a canonical failure code.        */
/* Returns: -1 to indicate fatal script error.                              */
/*--------------------------------------------------------------------------*/
fatalError:
  parse arg errorMsg
  say errorMsg
return -1  /* end function */

/*--------------------------------------------------------------------------*/
/* Exit Function:  cleanup                                                  */
/*--------------------------------------------------------------------------*/
/* Cleanup a connection and possibly a request handle if active.            */
/* Free all allocated DDs and post optional error message.                  */
/* Then EXIT the program                                                    */
/*--------------------------------------------------------------------------*/
cleanup:
  parse arg errorMsg
  /* Release the request handle */
  if g.rHandle <> '' then
    call HTTP_terminate g.rHandle,HWTH_NOFORCE
  /* Release the connection handle  */
  if g.cHandle <> '' then
    call HTTP_terminate g.cHandle,HWTH_NOFORCE
  /* Release the parser handle  */
  if g.pHandle <> '' then
     call JSON_termParser
  /* Free trace file if allocated */
  fname = getAlocFile(g.traceDD)
  if fname <> '' then
  do
    x = bpxwdyn("FREE FI("g.traceDD")")
    if g.verbose then
      say 'Freed allocated trace file:' fname ', RC:' x
  end
  /* Free Credentials file if allocated */
  fname = getAlocFile(g.authDD)
  if fname <> '' then
  do
    x = bpxwdyn("FREE FI("g.authDD")")
    if g.verbose then
      say 'Freed allocated Credentials file:' fname ', RC:' x
  end
  /* Free private key file if allocated */
  fname = getAlocFile(g.encrDD)
  if fname <> '' then
  do
    x = bpxwdyn("FREE FI("g.encrDD")")
    if g.verbose then
      say 'Freed allocated private key file:' fname ', RC:' x
  end
  /* Free output file if allocated */
  fname = getAlocFile(g.outDD)
  if fname <> '' then
  do
    x = bpxwdyn("FREE FI("g.outDD")")
    if g.verbose then
      say 'Freed allocated output file:' fname ', RC:' x
  end
  /* Say error message */
  if errorMsg <> '' then
    say 'Aborted:' errorMsg
  /* Convert -1 to 12 for valid return codes when running as job */
  if g.progRc < 0 then g.progRc = 12
exit g.progRc

