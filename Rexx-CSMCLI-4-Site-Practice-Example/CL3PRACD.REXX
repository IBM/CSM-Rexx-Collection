/* REXX */

/*****************************************************************************/
/* IBM Copy Services Manager script to create practice copy on 4th site:     */
/* ---------------------------------------------------------------------     */
/* It uses the CSMCLI to create a consistent practice copy on 4th site of a  */
/* four site replication topology with a MM-GM-GC 4-site session.            */
/*                                                                           */
/* These process steps are used:                                             */
/* ----------------------------                                              */
/* 0) Check for Prepared state of H1-J3 pairs in session and Preparing       */
/*    State of H3-H4 pairs in cascaded GC role pair with progress >= xx %)   */
/* 1) Suspend H1-H3 (GM leg) of session and wait until suspended             */
/* 2) FailoverH3 of session and wait until completed                         */
/*    Wait for previous Suspended (Partially) state and check H1-H3          */
/*    is recoverable and all H1-H3 pairs are Target Available                */
/* 3) Suspend cascaded GC of H3-H4 and wait until Suspended                  */
/* 4) StartGM H1-H3 (GM leg) of session to minimize GM RPO impact            */
/*    Wait for Prepared state of all H1-H3 pairs                             */
/* 5) Failover cascaded GC of H3-H4 and wait until Target Available          */
/*    Check that H3-H4 is recoverable                                        */
/* If there are errors in step 1-5 or if an optional task is executed,       */
/* the script will try to restore original GM and cascaded GC replication.   */
/*                                                                           */
/* Optional Input Parameters:                                                */
/* --------------------------                                                */
/* acsm=addr: Hostname or IP address of CSM server having the Active role.   */
/*            This will overwrite the defined 'actcsm' value of the script.  */
/* sess=name: Name of the 4-site session to be used.                         */
/*            This will overwrite the defined 'deffsess' value of the script.*/
/*            Name is case sensitive and single/double quotes must be used   */
/*            if it contains spaces. Either session name is required.        */
/* task=name: Name of the 4-site session scheduled task to be used instead   */
/*            of script steps 1-5 (Optional). Script will then run the task, */
/*            monitor its completion, and restore replication in case of task*/
/*            error. Name is case sensitive and single/double quotes must be */
/*            used if it contains spaces.                                    */
/* pchk=off : This will disable the Pre-Checks of the script (step 0). It    */
/*            can be used if proper pre-checks are included in a given task. */
/* dbug=lvl : This will set the debug level of the script. It can be used to */
/*            increase output details in case of unexpected errors.          */
/*            Supported levels are 0 (default), 2 and 9                      */
/*                                                                           */
/* The script has following overall return codes:                            */
/* ----------------------------------------------                            */
/* 0 :Practice Copy was created and GM is back in Prepared state             */
/* 4 :Practice Copy was created, but GM could not be restarted within timeout*/
/* 8 :Practice Copy creation failed, but previous replication was restarted  */
/* 12:Precheck error or practice copy as well as replication restart failed  */
/* 16:System environment for script cannot be established or missing parms   */
/*                                                                           */
/*****************************************************************************/
/* COPYRIGHT INFORMATION AND DISCLAIMER:                                     */
/* This program is licensed under the Apache License 2.0. You may obtain     */
/* a copy of the License at http://www.apache.org/licenses/LICENSE-2.0       */
/* It is a permissive license whose main conditions require preservation of  */
/* copyright and license notices. Contributors provide an express grant of   */
/* patent rights. Licensed works, modifications, and larger works may be     */
/* distributed under different terms and without source code. This           */
/* program is provided for tutorial purposes only. A complete handling of    */
/* error conditions has not been shown or attempted, and this program has    */
/* not been submitted to formal IBM testing. This program is distributed on  */
/* an 'as is' basis without any warranties either expressed or implied.      */
/*                                                                           */
/* Copyright IBM Corporation 2019                                            */
/*****************************************************************************/

/* Modify environment for script */
pricsm = ""                           /* Primary CSM server IP/Name          */
seccsm = ""                           /* Secondary CSM server IP/Name        */
actcsm = pricsm                       /* CSM server with Active role         */
stdcsm = seccsm                       /* CSM server with Standby role        */

/* Define def. parameters, extra single quotes are mandatory if space in name*/
defsess = "''"                        /* Name of active MM-GM-GC session     */
deftask = "''"                        /* Name of task to run alternatively   */

/* Modify scenario parameters as required */
gcprog    = 97                        /* Min. prog % of GC rolepair at start */
gmsuspto  = 300                       /* max sec. for GM Suspend completion  */
gcsuspto  = 120                       /* max sec. for GC Suspend completion  */
frrto     = 120                       /* max sec. for FRR completion         */
mmrecto   = 60                        /* max sec. for MM Recovery completion */
gmstartto = 300                       /* max sec. for GM Restart completion  */
gcstartto = 60                        /* max sec. for GC Restart completion  */
gcstopto  = 120                       /* max sec. for GC Stop (err. recovery)*/
taskto    = 600                       /* max sec. for task duration          */

/* Mofify environment for CSMCLI calls */
env.0 = 2                                      /* # of entries in env.       */
env.1 = "HOME=/u/username"                     /* Home for auth file         */
env.2 = "PATH=/bin:/opt/IBM/CSM/CLI/"          /* Path to csmcli.sh & bin    */
cliex = "csmcli.sh -noinfo"                    /* default executable         */
dlmch = ";"                                    /* Delimiter char for output  */
/* Note: This script does not include CSMCLI username or password. It relies */
/* that the CSMCLI authentication properties file is setup in the CSM-CLI    */
/* subfolder of the specified HOME folder:                                   */
/*   <HOME>/csm-cli/csmcli-auth.properties                                   */

/* Set Debug level for additional output */
debug  = 0                            /* Set >0 for more debug output        */
                                      /* 2: print more output of procedures  */
                                      /* 9: print also CSMCLI call details   */


/* Define output formatting */
tab    = "       "                    /* Tab to structure sub output         */
line   = left("-",79,"-")

/* Define global Session variables to keep latest info from last query */
GSname = ""   /* Session Name                        */
GSstate= ""   /* Session State                       */
GSrp   = ""   /* Specific Role Pair if applicable    */
GShost = ""   /* Session active Host                 */
GSrecov= ""   /* Recoverability of Session/Rolepair  */
GSprog = ""   /* Progress of Rolepair                */
GScpset= ""   /* Qty of Copy Sets in Session         */

/* Get Session parameters */
parse arg parms

/* extract parms and assign values*/
s4sess = ""
s4task = ""
s4pchk = ""
prest = parms
do while prest <> ""
  parse var prest parm '=' prest
  if prest <> "" then do
    /* extract word before = */
    parm = translate(word(parm,words(parm)))
    qchar = left(word(prest,1),1)
    if qchar = '"' | qchar = "'" then do
      /* lookup matching quote char for full value*/
      parse var prest (qchar) pval (qchar) prest
    end
    else do
      pval = word(prest,1)
    end
    if parm = "SESS" & pval <> "" then do
      s4sess = pval
    end
    else if parm = "TASK" & pval <> "" then do
      s4task = pval
    end
    else if parm = "PCHK" & translate(pval) = "OFF" then do
      s4pchk = "DISABLED"
    end
    else if parm = "ACSM" & pval <> "" then do
      actcsm = pval
    end
    else if parm = "DBUG" & pval <> "" then do
      if datatype(pval,'W') then do
        if pval > 0 then debug = pval
      end
    end
  end
end

/* Set defaults if no parameter defined */
if s4pchk = "" then s4pchk = "ENABLED"   /* Precheck enabled per default */
if s4sess = "" then s4sess = strip(defsess,"B","'")
if s4task = "" then s4task = strip(deftask,"B","'")
s4sess = "'"s4sess"'"
s4task = "'"s4task"'"
cliex = cliex "-server" actcsm           /* append active server to exec */
totrc = 0

/* Get Operating System and print used parameters */
parse upper source osfull .

runtime = time('E')
say line
say LOGI("Creating Practice Copy on Site 4 (D volumes):")
say LOGI("4-site Session:" s4sess)
say LOGI("Session task  :" s4task)
say LOGI("Pre-Checks    :" s4pchk)
say LOGI("CSM Server    :" actcsm)
say LOGI("Local O/S     :" osfull)
say LOGI("Debug Level   :" debug)
say line
say

/* Verify required parameters for execution are given */
if s4sess = "''" then do
  say LOGI("ERROR: Missing 4-site Session name.")
  totrc = 16
end
if actcsm = "" then do
  say LOGI("ERROR: Missing CSM server IP/hostname.")
  totrc = 16
end
if totrc <> 0 then do
  say LOGI("Total RC     =" totrc)
  say line
  return totrc
end

/* Verify and Prepare System environment */
totrc = PREPAREENV()
if totrc <> 0 then do
  say LOGI("ERROR: Failed to prepare system environment for:" osfull)
  say LOGI(totrc)
  totrc = 16
  say LOGI("Total RC     =" totrc)
  say line
  return totrc
end


/*****************************************************************************/
/* Start the sequence                                                        */
/*****************************************************************************/

/* Run precheck first if enabled */
if s4pchk = "DISABLED" then do
  totrc = 0
end 
else do
  totrc = PRECHECK()
end

/* If precheck failed, exit */
if totrc <> 0 then do
  say LOGI("Precheck ERROR:" totrc)
  totrc = 12
  say LOGI("Total RC     =" totrc)
  say line
  return totrc
end


/* Create Practice copy on D */
say line
say
/* Run given task if specified, otherwise use script */
if s4task <> "''" then do
  totrc = RUNTASK()
  if totrc <> 0 & GTid = "" then do
    /* Error but Task was not started yet, exit without repl restart */
    say LOGI("Task start ERROR:" totrc)
    totrc = 12
    say LOGI("Total RC     =" totrc)
    say line
    return totrc
  end
end
else do
  totrc = CREATEPRACTICED()
end
if totrc <> 0 then say LOGI("ERROR:" totrc)
say line
say

/* Restart replication */
enabrc = totrc
if totrc = 0 & s4task = "''" then do
  say line
  /* Practice data OK, restart only GM */
  say LOGI("Successfully created practice Copy on Site 4 (D volumes)")
  say LOGI("Restarting Global Mirror to restore site protection...")
  say line
  say
  totrc = RESTARTGM()
  if totrc <> 0 then say LOGI("ERROR:" totrc)
  say line
  say
  say line
  if totrc <> 0 then do
    say LOGI("WARNING: Failed to restart Global Mirror.")
    totrc = 4
  end
  else do
    say LOGI("Global Mirror returned to Prepared State.")
  end
  /* Enable practice copy on H4 */
  say LOGI("Enabling practice Copy on Site 4 (D volumes)...")
  say line
  say
  enabrc = ENABLEPRACTICED()
  if enabrc <> 0 then do
    say LOGI("ERROR:" enabrc)
    say LOGI("Failed to enable practice Copy on Site 4.")
  end
  say line
  say
end

/* Recover replication states if error occured */
say line
if enabrc = 0 then do
  if s4task <> "''" then do
    say LOGI("Successfully completd task to create practice Copy on Site 4" ,
            "(D volumes)")
  end
  else do 
    say LOGI("Successfully enabled practice Copy on Site 4.")
  end
  say LOGI("Systems can be IPLed on Site 4 for testing.")
end
else do
  /* Script or task failed, try to restart GM and GC */
  if s4task <> "''" then do
    say LOGI("Failed to complete task for practice Copy on Site 4 (D volumes)")
  end
  else do
    say LOGI("Failed to enable a practice Copy on Site 4 (D volumes)")
  end
  say LOGI("Restarting Global Mirror and cascaded Global Copy to restore")
  say LOGI("original states of session...")
  say line
  say
  totrc = RESTARTSESSIONS()
  say line
  if totrc <> 0 then do
    say LOGI("Practice Copy on D volumes failed, and failed to restart")
    say LOGI("original replication. Please verify state of Session" s4sess)
    say LOGI("and restart replication manually.")
    totrc = 12
  end
  else do
    say LOGI("Practice Copy on D volumes failed, but original replication")
    say LOGI("in 4-site session" s4sess "was restarted successfully.")
    totrc = 8
  end
end

say line
say
say line
say LOGI("Total Runtime:" GETRUNTIME(runtime))
say LOGI("Total RC     =" totrc)
say line
return totrc


/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Precheck routine to validate everything is OK for CSMCLI sequence.      -*/
/*- It performs Step 0 of the overall sequence.                             -*/
/*- Return codes:                                                           -*/
/*- 0     : All checks are OK                                               -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
PRECHECK:
  /* Step 0: Check MT session H1-J3 prepared, GC session H1-H2 is preparing */
  /* Step 0: Check GC session progress least min defined progress for start */
  step = 0
  steptime = time('E')
  sess  = s4sess
  state = "Prepared"
  rolep = "H1-J3"
  say LOGS(step,"Check for" state "state of" rolep "pairs in session" sess"...")
  cmdrc = CHKPAIRSTATE(sess,rolep,state)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" state "state of" rolep "pairs in" sess)
    return cmdrc
  end
  say LOGS(step,"All pairs of" rolep "in" sess "are" state)
  state = "Preparing"
  rolep = "H3-H4"
  minprog = gcprog
  say LOGS(step,"Check for" state "state of" rolep "pairs in session" sess"...")
  cmdrc = CHKPAIRSTATE(sess,rolep,state)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" state "state of" rolep "pairs in" sess)
    return cmdrc
  end
  say LOGS(step,"Check" rolep "Progress >=" minprog "% in session" sess"...")
  cmdrc = CHKRP(sess,rolep,,minprog)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" rolep "progress in" sess)
    return cmdrc
  end
  say LOGS(step,"Progress of" rolep "in" sess "is >=" minprog "%")
  say LOGS(step,"Pre-Check completed successfully")
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Sequence to create a practice copy on D volumes                         -*/
/*- It performs Step 1-3 of the overall sequence.                           -*/
/*- Return codes:                                                           -*/
/*- 0     : All steps executed successfully                                 -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CREATEPRACTICED:
  /* Step 1: Suspend GM leg of MT session and wait for completion */
  step = 1
  steptime = time('E')
  sess  = s4sess
  command = "SuspendH1H3"
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    return cmdrc
  end
  say LOGS(step,"Successfully issued" command "to 4-site session" sess)
  validstates = "Suspended, Suspended (Partial)"
  timeout = gmsuspto   /* max wait time for GM suspend completion */
  say LOGS(step,"Waiting for suspend completion of 4-site session" sess ,
                "(max." timeout "s)...")
  cmdrc = CHKSESSSTATE(sess,validstates,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while waiting for session" sess "to reach valid state")
    return cmdrc
  end
  say LOGS(step,"Successfully suspended H1-H3 of 4-site session" sess)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  /* Step 2: Failover GM leg of MT session and wait until H3 is consistent */
  step = 2
  steptime = time('E')
  sess  = s4sess
  /* Get last session state from Globals from previos suspend check */
  oldstate = "???"
  say LOGS(step,"Determine state of 4-site session" sess "from previous query")
  if debug >= 2 then say LOGD(2,"GSname="GSname", GSrp="GSrp", GSstate="GSstate)
  if GSname = sess & GSrp = "" & GSstate <> "" then oldstate = GSstate
  say LOGS(step,sess "session state is:" oldstate)
  if oldstate ="???" then do
    say LOGS(step,"Could not determine last state from previous query of " sess)
    return 8
  end

  command = "FailoverH3"
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    return cmdrc
  end
  say LOGS(step,"Successfully issued" command "to 4-site session" sess)
  validstates = oldstate               /* wait until previous state reached */
  timeout = frrto                      /* max wait time for FRR completion  */
  say LOGS(step,"Waiting for failover completion of 4-site session" sess ,
                "(max." timeout "s)...")
  cmdrc = CHKSESSSTATE(sess,validstates,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while waiting for session" sess ,
              "to become:" validstates)
    return cmdrc
  end

  state = "Target Available"
  rolep = "H1-H3"
  say LOGS(step,"Check" state "state of" rolep "pairs in" sess"...")
  cmdrc = CHKPAIRSTATE(sess,rolep,state)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" state "state of" rolep "in" sess)
    return cmdrc
  end
  say LOGS(step,"All pairs of" rolep "in" sess "are" state)

  rolep = "H1-H3"
  say LOGS(step,"Check" rolep "is recoverable in session" sess"...")
  cmdrc = CHKRP(sess,rolep,"YES")
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" rolep ,
               "is recoverable in session" sess)
    return cmdrc
  end
  say LOGS(step,rolep "in" sess "is recoverable")
  say LOGS(step,"H3 volumes are consistent in 4-site session" sess)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  /* Step 3: Suspend cascaded GC rolepair and wait for completion */
  step = 3
  steptime = time('E')
  sess  = s4sess
  command = "SuspendH3H4"
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    return cmdrc
  end
  say LOGS(step,"Successfully issued" command "to 4-site session" sess)
  validstates = "Suspended, Suspended (Partial)"
  timeout = gcsuspto   /* max wait time for GC suspend completion */
  say LOGS(step,"Waiting for suspend completion of 4-site session" sess ,
                "(max." timeout "s)...")
  cmdrc = CHKSESSSTATE(sess,validstates,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while waiting for session" sess ,
         "to become:" validstates)
    return cmdrc
  end
  say LOGS(step,"Successfully suspended GC of 4-site session" sess)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Restart Global Mirror of 4-site session                                 -*/
/*- It performs Step 4 of the overall sequence.                             -*/
/*- Return codes:                                                           -*/
/*- 0     : All steps executed successfully                                 -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
RESTARTGM:
  /* Step 4: StartGMH1-H3 of 4-site session and wait until H1-J3 prepared */
  step = 4
  steptime = time('E')
  sess  = s4sess
  command = "StartGM_H1:H3"
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during start of H1-H3 of 4-site session" sess)
    return cmdrc
  end
  say LOGS(step,"Successfully issued" command "to 4-site session" sess)

  state = "Prepared"
  rolep = "H1-J3"
  timeout = gmstartto /* max wait time for GM Restart completion */
  say LOGS(step,"Waiting for" state "state of" rolep "pairs in session" sess ,
                "(max." timeout "s)...")
  cmdrc = CHKPAIRSTATE(sess,rolep,state,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" state "state of" rolep ,
                "pairs in" sess)
    return cmdrc
  end
  say LOGS(step,"All pairs of" rolep "in" sess "are" state)
  say LOGS(step,"Successfully restarted H1-H3 of 4-site session" sess)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Sequence to enable a practice copy on D volumes (Failover)              -*/
/*- It performs Step 5 of the overall sequence.                             -*/
/*- Return codes:                                                           -*/
/*- 0     : All steps executed successfully                                 -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
ENABLEPRACTICED:
  /* Step 5: Failover cascaded GC rolepair and wait until completed */
  step = 5
  steptime = time('E')
  sess  = s4sess
  command = "FailoverH4"
  say LOGS(step,command "of 4-site session" sess)
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    return cmdrc
  end
  say LOGS(step,"Successfully issued" command "to 4-site session" sess)

  state = "Target Available"
  rolep = "H3-H4"
  timeout = mmrecto  /* max wait time for MM Recovery completion */
  say LOGS(step,"Check" state "state of" rolep "pairs in" sess"...")
  cmdrc = CHKPAIRSTATE(sess,rolep,state,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" state "state of" rolep "in" sess)
    return cmdrc
  end
  say LOGS(step,"All pairs of" rolep "in" sess "are" state)

  rolep = "H3-H4"
  say LOGS(step,"Check" rolep "is recoverable in session" sess"...")
  cmdrc = CHKRP(sess,rolep,"YES")
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking" rolep ,
               "is recoverable in session" sess)
    return cmdrc
  end
  say LOGS(step,rolep "in" sess "is recoverable")
  say LOGS(step,"Successfully recovered H4 volumes in 4-site session" sess)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Restart 4-site session in case there was an error in the sequence       -*/
/*- It performs a check whether GC or GM rolepair is in a state that might  -*/
/*- require a Stop first (step R0). Then it performs a restart of           -*/
/*- cascaded GC (step R1) and a restart of GM (step R2) in 4-site session   -*/
/*- Return codes:                                                           -*/
/*- 0     : All steps executed successfully                                 -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
RESTARTSESSIONS:
  /* Step R0: Check whether Session might require a stop command */
  step = "R0"
  steptime = time('E')
  sess  = s4sess
  myerror = 0
  say LOGS(step,"Check if state of 4-site session" sess "requires a Stop" ,
                "command for the GC or GM rolepair...")
  validstates = "Draining,Suspending"
  cmdrc = CHKSESSSTATE(sess,validstates)
  if cmdrc <> 0 then do
    /* Good state which does not require a Stop */
    say LOGS(step,"Session state" GSstate "does not require a Stop command")
  end
  else do
    /* Bad state which requires a Stop first */
    /* Ignore errors in attempt to recover unexpected state of the pairs */
    if GSstate = "DRAINING" then do
      rolep = "H3-H4"
      command = "Stoph3h4"
      state = "Suspended"
    end
    else if GSstate = "SUSPENDING" then do
      rolep = "H1-H3"
      command = "Stoph1h3"
      state = "Suspended"
    end
    say LOGS(step,"Session state" GSstate "requires a Stop" ,
                  "command for rolepair" rolep)
    say LOGS(step,command "of 4-site session" sess"...")
    cmd = cliex "cmdsess -quiet -action" command sess
    cmdrc = CLI(cmd)
    if cmdrc <> 0 then do
      say LOGS(step,"Error during" command "of 4-site session" sess)
      say LOGI("ERROR:" cmdrc)
    end
    else do
      say LOGS(step,"Successfully issued" command "of 4-site session" sess)
      timeout = gcstopto   /* max wait time for GC stop completion */
      say LOGS(step,"Waiting for stop completion of 4-site session" sess ,
                    "(max." timeout "s)...")
      cmdrc = CHKPAIRSTATE(sess,rolep,state,timeout)
      if cmdrc <> 0 then do
        say LOGS(step,"Error while waiting for rolepair" rolep ,
              "of 4-site session" sess "to become:" state)
      end
      else do
        say LOGS(step,"Successfully stopped" rolep "of 4-site session" sess)
      end
    end
  end
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say
  
  /* Step R1: StartGC of cascaded rolepair and wait for prepairing state */
  step = "R1"
  steptime = time('E')
  sess  = s4sess
  command = "StartGC_H3:H4"
  myerror = 0
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    say LOGI("ERROR:" cmdrc)
    myerror = cmdrc
    /* return cmdrc      Ignore error at this point, try to restart also GM */
  end
  else do
    say LOGS(step,"Successfully issued" command "of 4-site session" sess)
    /* Wait for preparing state if there are no errors on start */
    state = "Preparing"
    rolep = "H3-H4"
    timeout = gcstartto     /* max wait time for GC start (Prepairing) */
    say LOGS(step,"Waiting for" state "state of" rolep "pairs in" ,
                  "4-site session" sess "(max." timeout "s)...")
    cmdrc = CHKPAIRSTATE(sess,rolep,state,timeout)
    if cmdrc <> 0 then do
      say LOGS(step,"Error while checking" state "state of" rolep ,
                  "pairs in" sess)
      say LOGI("ERROR:" cmdrc)
      myerror = cmdrc
      /* return cmdrc    Ignore error at this point, try to restart also GM */
    end
    else do
      say LOGS(step,"All pairs of" rolep "in" sess "are" state)
    end
  end
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  /* Step R2: StartGM_H1-H3 of 4-site session and wait until H1-J3 prepared */
  step = "R2"
  steptime = time('E')
  sess  = s4sess
  command = "StartGM_H1:H3"
  say LOGS(step,command "of 4-site session" sess"...")
  cmd = cliex "cmdsess -quiet -action" command sess
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error during" command "of 4-site session" sess)
    say LOGI("ERROR:" cmdrc)
    myerror = cmdrc
  end
  else do
    say LOGS(step,"Successfully issued" command "to 4-site session" sess)

    state = "Prepared"
    rolep = "H1-J3"
    timeout = gmstartto      /* max wait time for GM Restart completion */
    say LOGS(step,"Waiting for" state "state of" rolep "pairs in session" sess ,
                  "(max." timeout "s)...")
    cmdrc = CHKPAIRSTATE(sess,rolep,state,timeout)
    if cmdrc <> 0 then do
      say LOGS(step,"Error while checking" state "state of" rolep ,
                  "pairs in" sess)
      say LOGI("ERROR:" cmdrc)
      myerror = cmdrc
    end
    else do
      say LOGS(step,"All pairs of" rolep "in" sess "are" state)
    end
  end
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  return myerror


/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Check status of given taskname and run the task ID                      -*/
/*- Monitor task status and wait for task completion.                       -*/
/*- The task should contain step 1-5 of this script                         -*/
/*- Return codes:                                                           -*/
/*- 0     : Task found and completed successfully                           -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
RUNTASK:
  /* Step T0: Prechecking for an inactive scheduled task */
  step = "T0"
  steptime = time('E')
  task = s4task
  taskid = ""
  tasksts = ""
  taskmsg = ""
  say LOGS(step,"Checking task" task"...")
  cmdrc = CHKTASK(task,"YES")
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking task" task)
    call RESETGLOBALS  /* reset Globals to indicate nothing started */
    return cmdrc
  end
  taskid = GTid
  tasksts = GTstate
  say LOGS(step,"Found inactive task" taskid":"task)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  /* Step T1: Run task ID */
  step = "T1"
  steptime = time('E')
  say LOGS(step,"Starting task" taskid":"task"...")
  cmd = cliex "runtask -quiet" taskid
  cmdrc = CLI(cmd)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while starting task" taskid":"task)
    call RESETGLOBALS  /* reset Globals to indicate nothing started */
    return cmdrc
  end
  say LOGS(step,"Successfully started task" taskid":"task)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  say line
  say

  /* Step T2: Wait for task ID completion */
  step = "T2"
  steptime = time('E')
  timeout = taskto                   /* max wait time for task completion */
  say LOGS(step,"Checking completion of task" taskid":"task"...")
  cmdrc = CHKTASK(task,,timeout)
  if cmdrc <> 0 then do
    say LOGS(step,"Error while checking completion of task" taskid":"task)
    return cmdrc
  end
  taskmsg = word(GTmsg,1)
  /* IWNR2212I [timestamp] The scheduled task VALUE_1 has finished running. */
  if taskmsg <> "IWNR2212I" then do
    cmdrc = "Task finished with unexpected message:" taskmsg
    return cmdrc
  end
  say LOGS(step,"Successfully finished task" taskid":"task)
  say LOGS(step,"Runtime" GETRUNTIME(steptime))
  return 0


/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Check all pairs in given session & role pair are in the given           -*/
/*- state. Optionally specify timeout in sec how long to wait for state.    -*/
/*- (It uses CSMCLI lspair -l -rolepair command)                            -*/
/*- Eg: call CHKPAIRSTATE(session,rolepair,state(,timeout))                 -*/
/*-     session : String with Session name, use '' if it includes spaces    -*/
/*-     rolepair: String with rolepair to use for pair state check          -*/
/*-     state   : String with state to be validated                         -*/
/*-     timeout : 0-3600 sec (optional, use to wait for given state)        -*/
/*- Return codes:                                                           -*/
/*- 0     : All checks are OK                                               -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CHKPAIRSTATE:
  parse arg sess1, rp1, state1, to1
  rp1 = translate(rp1)
  state1 = translate(state1)
  mytime = time('E')
  if debug >= 2 then do
    say LOGD(2,"CHKPAIRSTATE parameters:" sess1","rp1","state1","to1)
  end
  call RESETGLOBALS                              /* reset Global variables   */
  mysess = strip(sess1,,"'")                     /* remove optional '        */
  if to1 = "" then to1 = 0                       /* Default to 0             */
  /* calculate delay based on timout value */
  mydelay = GETDELAY(to1)
  if mydelay < 0 then do
    myrc = "Invalid timeout specified:" to1 "(Valid 0-3600)"
    return myrc
  end
  if debug >= 2 then say LOGD(2,"Specified timeout:" to1 "=> Delay" ,
                           mydelay "sec")
  cmd = cliex "lspair -l -fmt delim -delim '"||dlmch||"' -rolepair" rp1 sess1
  do while 1
    myrc = CLI(cmd)
    if myrc = 0 then do
      /* Count pairs with required state and also all other found states */
      totalpairs = 0
      /* Predefine found states with given state */
      foundstates= translate(state1,'_',' ') /* Replace blank with _ */
      statescount.0 = 1 /* qty of found states, preset given state */
      statescount.1 = 0 /* pre-define found qty of given state = 0 */
      do i=1 to out.0
        /* Parse output fields */
        /* Source Volume;Target Volume;Role Pair;State;Recoverable;Copying;  */
        /* Progress;New;Copy Set;Timestamp;Last Result                       */
        parse upper var out.i p1 (dlmch) ,
              p2 (dlmch) ,
              p3 (dlmch) ,
              p4 (dlmch) , .
        if debug >= 2 then say LOGD(2,p1","p2","p3","p4)
        if p3 = rp1 then do
          totalpairs = totalpairs + 1
          paddedp4 = translate(p4,'_',' ') /* Replace blank with _ */
          idx = wordpos(paddedp4,foundstates)  /* Check if state known */
          if idx > 0 then do
            /* increase count for found state */
            statescount.idx = statescount.idx + 1
          end
          else do
            /* add new found state */
            foundstates = foundstates paddedp4
            idx = statescount.0 + 1
            statescount.idx = 1
            statescount.0 = idx
          end
        end
      end
      say LOGI(tab sess1 rp1 "Pair state result:")
      say LOGI(tab format(totalpairs,4) "pairs total:")
      if totalpairs > 0 then do
        do j = statescount.0 to 1 by -1
          statej = translate(word(foundstates,j),' ','_')
          say LOGI(tab format(statescount.j,6) "pairs" statej)
        end
        if totalpairs = statescount.1    then do
          /* Update Global Session variables only if all pairs equal state */
          GSname = sess1 /* keep single quotes included in name */
          GSrp   = p3
          GSstate= state1
          GScpset= totalpairs
          return 0                               /* all conditions met */
        end
      end
      else do
        myrc = "No pairs found."
        return myrc
      end
    end
    else do
      if debug >= 2 then say LOGD(2,"ERROR: '"myrc"' while listing pairs")
      return myrc                                /* CSMCLI error  */
    end
    /* apply delay prior next call if necessary */
    if debug >= 2 then do
      say LOGD(2,"Elapsed:" time('E') - mytime "sec")
      say LOGD(2,"mydelay:" mydelay "sec")
      say LOGD(2,"Timeout:" to1 "sec")
    end
    if time('E') - mytime + mydelay >= to1 then do
      myrc = "Invalid States found."
      if to1 > 0 then myrc = "Wait timeout of" to1 "sec exceeded."
      return myrc                                /* Invalid states */
    end
    else do
      say LOGI(tab "Need to wait for valid state:" state1)
      say LOGI(tab "Requerying in" mydelay "sec...")
      call WAIT(mydelay)
    end
  end
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Check that session reached any of the provided states                   -*/
/*- Optionally specify timeout in sec how long to wait for valid state.     -*/
/*- (It uses CSMCLI lssess -l command)                                      -*/
/*- Eg: call CHKSESSSTATE(session,states(,timeout))                         -*/
/*-     session: String with Session name, use '' if it includes spaces     -*/
/*-     states : String with comma separated valid states (Use empty string -*/
/*-              without timeout to update global variable with state info) -*/
/*-     timeout: 0-3600 sec (optional, use to wait for given state)         -*/
/*- Return codes:                                                           -*/
/*- 0     : All checks are OK                                               -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CHKSESSSTATE:
  states2 = ""                                   /* preset to empty string   */
  parse arg sess2, states2, to2
  mytime = time('E')
  if debug >= 2 then do
    say LOGD(2,"CHKSESSSTATE parameters:" sess2","states2","to2)
  end
  call RESETGLOBALS                              /* reset Global variables   */
  mysess = strip(sess2,,"'")                     /* remove optional '        */
  if to2 = "" then to2 = 0                       /* Default to 0             */
  /* calculate delay based on timout value */
  mydelay = GETDELAY(to2)
  if mydelay < 0 then do
    myrc = "Invalid timeout specified:" to2 "(Valid 0-3600)"
    return myrc
  end
  if debug >= 2 then say LOGD(2,"Specified timeout:" to2 "=> Delay" ,
                           mydelay "sec")
  cmd = cliex "lssess -l -fmt delim -delim '"||dlmch||"'" sess2
  do while 1
    myrc = CLI(cmd)
    if myrc = 0 then do
      mystate = "???"
      do i=1 to out.0
        /* Parse output fields */
        /* Name;Status;State;Copy Type;Recoverable;Copying;Copy Sets;        */
        /* Error;Group                                                       */
        parse var out.i p1 (dlmch) ,
              p2 (dlmch) ,
              p3 (dlmch) ,
              p4 (dlmch) ,
              p5 (dlmch) ,
              p6 (dlmch) ,
              p7 (dlmch) , .
        if debug >= 2 then say LOGD(2,p1","p2","p3","p4","p5","p6","p7)
        if p1 = mysess then do
          mystate = p3
          /* Update Global Session variables */
          GSname = sess2 /* keep single quotes included in name */
          GSstate= translate(mystate)
          GSrecov= translate(p5)
          GScpset= p7
        end
      end
      say LOGI(tab sess2 "session state is:" mystate)
      /* check if valid state reached */
      mystates = translate(states2)
      mystate = translate(mystate)
      if mystates = "" then return 0 /* quit immediately, no check required  */
      do while mystates <> ""
        parse var mystates nextstate ',' mystates
        if strip(nextstate) = mystate then do
          return 0                               /* all conditions met */
        end
      end
    end
    else do
      if debug >= 2 then say LOGD(2,"ERROR: '"myrc"' while listing session")
      return myrc                                /* CSMCLI error  */
    end
    /* apply delay prior next call if necessary */
    if debug >= 2 then do
      say LOGD(2,"Valid states:" states2)
      say LOGD(2,"mydelay:" mydelay "sec")
      say LOGD(2,"Timeout:" to2 "sec")
    end
    if time('E') - mytime + mydelay >= to2 then do
      myrc = "Invalid state found."
      if to2 > 0 then myrc = "Wait timeout of" to2 "sec exceeded."
      return myrc                                /* Invalid states */
    end
    else do
      say LOGI(tab "Need to wait for valid state:" states2)
      say LOGI(tab "Requerying in" mydelay "sec...")
      call WAIT(mydelay)
    end
  end
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Check given role pair in session. Optionally check whether recoverable  -*/
/*- or whether progress exceeds a given percentage.                         -*/
/*- Optionally specify timeout in sec how long to wait for required condit. -*/
/*- (It uses CSMCLI lsrolepair -l command)                                  -*/
/*- Eg: call CHKRP(session,rolepair,(recoverable,minprogress)(,timeout)     -*/
/*-     session: String with Session name, use '' if it includes spaces     -*/
/*-     rolepair: String with rolepair to use for pair state check          -*/
/*-     recoverable: (optional) Specify "YES" to validate recoverability    -*/
/*-     minprogress: 0-100 % (optional, min. Progress in % to be validated) -*/
/*-     timeout: 0-3600 sec (optional, use to wait for given state)         -*/
/*- Return codes:                                                           -*/
/*- 0     : All checks are OK                                               -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CHKRP:
  parse arg sess3, rp3, recov3, minprog3, to3
  rp3 = translate(rp3)
  recov3 = translate(recov3)
  mytime = time('E')
  if debug >= 2 then do
    say LOGD(2,"CHKRP parameters:" sess3","rp3","recov3","minprog3","to3)
  end
  call RESETGLOBALS                              /* reset Global variables   */
  mysess  = strip(sess3,,"'")                    /* remove optional '        */
  if to3 = "" then to3 = 0                       /* Default to 0             */
  /* calculate delay based on timout value */
  mydelay = GETDELAY(to3)
  if mydelay < 0 then do
    myrc = "Invalid timeout specified:" to3 "(Valid 0-3600)"
    return myrc
  end
  if debug >= 2 then say LOGD(2,"Specified timeout:" to3 "=> Delay" ,
                           mydelay "sec")
  cmd = cliex "lsrolepairs -l -fmt delim -delim '"||dlmch||"'" sess3
  do while 1
    myrc = CLI(cmd)
    if myrc = 0 then do
      /* Check specified conditions */
      bad = 0
      do i=1 to out.0
        /* Parse output fields */
        /* Name;Recoverable;Error;Copying;Copy Type;Progress;Error Volumes; */
        /* Recoverable Pairs;Copying Pairs;Total Pairs;Recovery Time;CG Name*/
        parse upper var out.i p1 (dlmch) ,
              p2 (dlmch) ,
              p3 (dlmch) ,
              p4 (dlmch) ,
              p5 (dlmch) ,
              p6 (dlmch) ,
              p7 (dlmch) ,
              p8 (dlmch) ,
              p9 (dlmch) ,
              p10 (dlmch) , .
        if debug >= 2 then say LOGD(2,p1","p2","p3","p4","p5","p6)
        if p1 = rp3 then do
          say LOGI(tab sess3 rp3 "Rolepair status:")
          say LOGI(tab "Recoverable:" p2)
          say LOGI(tab "Progress % :" p6)
          /* Update Global Session variables */
          GSname = sess3 /* keep single quotes included in name */
          GSrp   = p1
          GSrecov= p2
          GSprog = p6
          GScpset= p10
          if recov3 <> ""  & recov3 <> p2 then do
            bad = bad + 1
            if debug >= 2 then say LOGD(2,"Recoverability not met.")
          end
          if datatype(p6) <> "NUM" then p6 = -1  /* Ensure Progress is NUM */
          if datatype(minprog3) = "NUM" then do
            if p6 < minprog3 then do
              bad = bad + 1
              if debug >= 2 then say LOGD(2,"Minimum Progress not met.")
            end
          end
        end
      end
      if bad = 0 then return 0                   /* All conditions met */
    end
    else do
      if debug >= 2 then say LOGD(2,"ERROR: '"myrc"' while listing rolepair")
      return myrc                                /* CSMCLI error  */
    end
    /* apply delay prior next call if necessary */
    if debug >= 2 then do
      say LOGD(2,"Elapsed:" time('E') - mytime "sec")
      say LOGD(2,"mydelay:" mydelay "sec")
      say LOGD(2,"Timeout:" to3 "sec")
    end
    if time('E') - mytime + mydelay >= to3 then do
      myrc = "Invalid rolepair conditions."
      if to3 > 0 then myrc = "Wait timeout of" to3 "sec exceeded."
      return myrc
    end
    else do
      say LOGI(tab "Need to wait for valid rolepair conditions.")
      say LOGI(tab "Requerying in" mydelay "sec...")
      call WAIT(mydelay)
    end
  end
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Check if task name exists and what the status is. It will update global -*/
/*- task variables with state and last error message.                       -*/
/*- Optionally specify if check fails if task is active.                    -*/
/*- Optionally specify timeout in sec how long to wait for task completion. -*/
/*- (It uses CSMCLI lstask command)                                         -*/
/*- Eg: call CHKTASK(taskname(,vfyinactive)(,timeout))                      -*/
/*-     taskname: String with task name, use '' if it includes spaces       -*/
/*-     vfyinactive: (optional) Specify "YES" to fail check if active       -*/
/*-     timeout : 0-3600 sec (optional, use to wait for task completion)    -*/
/*- Return codes:                                                           -*/
/*- 0     : Task found and completed successfully                           -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CHKTASK:
  parse arg task1, vfyinact, to1
  mytime = time('E')
  mytaskid = ""
  if debug >= 2 then do
    say LOGD(2,"RUNTASK parameters:" task1","vfyinact","to1)
  end
  call RESETGLOBALS                              /* reset Global variables   */
  mytask = strip(task1,,"'")                     /* remove optional '        */
  if to1 = "" then to1 = 0                       /* Default to 0             */
  /* calculate delay based on timout value */
  mydelay = GETDELAY(to1)
  if mydelay < 0 then do
    myrc = "Invalid timeout specified:" to1 "(Valid 0-3600)"
    return myrc
  end
  if debug >= 2 then say LOGD(2,"Specified timeout:" to1 "=> Delay" ,
                           mydelay "sec")
  
  /* Check task status for specified taskname */
  cmd = cliex "lstasks -l -fmt delim -delim '"||dlmch||"'"
  do while 1
    myrc = CLI(cmd)
    if myrc = 0 then do
      do i=1 to out.0
        /* Parse output fields */
        /* ID;Name;Status;Schedule;Next Run Time;Last Run Time;Last Result  */
        parse var out.i p1 (dlmch) ,
              p2 (dlmch) ,
              p3 (dlmch) ,
              p4 (dlmch) ,
              p5 (dlmch) ,
              p6 (dlmch) ,
              p7 (dlmch) , .
        if debug >= 2 then say LOGD(2,p1","p2","p3","p4","p5","p6","p7)
        if p2 = mytask then do
          GTname = task1 /* keep single quotes included in name */
          GTid = p1
          GTstate = p3
          GTmsg = p7
          parse var p6 GTlrt "." .
          GTlrt = strip(GTlrt)
          leave
        end
      end
      if GTid <> "" then do
        say LOGI(tab "Task:"GTid " Status:"GTstate " Message:"GTmsg ,
                " LastRun:"GTlrt)
        /* check if task still running */
        if translate(p3) <> "RUNNING" then do
          return 0                               /* all conditions met */
        end
      end
      else do
        myrc = "Task not found:" task1
        return myrc
      end
    end
    else do
      if debug >= 2 then say LOGD(2,"ERROR: '"myrc"' while listing tasks")
      return myrc                                /* CSMCLI error  */
    end
    /* apply delay prior next call if necessary */
    if debug >= 2 then do
      say LOGD(2,"Elapsed:" time('E') - mytime "sec")
      say LOGD(2,"mydelay:" mydelay "sec")
      say LOGD(2,"Timeout:" to1 "sec")
    end
    if time('E') - mytime + mydelay >= to1 then do
      if vfyinact = "YES" then do
        myrc = "Task is running."
      end
      if to1 > 0 then myrc = "Wait timeout of" to1 "sec exceeded."
      return myrc                                /* Invalid states */
    end
    else do
      say LOGI(tab "Need to wait for task completion:" p3)
      say LOGI(tab "Requerying in" mydelay "sec...")
      call WAIT(mydelay)
    end
  end
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Call CSMCLI with specified cmd and verify RC & output streams.          -*/
/*- Any CSMCLI framework RC <> 0 will be passed back with more error details-*/
/*- It means the command could not be sent to the server.                   -*/
/*- If the output streams contain a CSMCLI Error message, the full message  -*/
/*- line will be returned.                                                  -*/
/*- 0 will be returned if the command was executed without Error message.   -*/
/*- Eg: call CLI(command)                                                   -*/
/*-     command: full single shot csmcli string including executable        -*/
/*- Return codes:                                                           -*/
/*- 0     : Command was executed without error                              -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
CLI:
  parse arg mycommand
  if debug >= 9 then say LOGD(9,"CLICMD:" mycommand)
  if os = "TSO" then do
    clirc = bpxwunix(mycommand,,out.,err.,env.)
  end
  else if os = "WIN" then do
    address SYSTEM mycommand WITH OUTPUT STEM out. ERROR STEM err.
    clirc = RC
  end
  else return "ERROR: Unknown O/S to run CSMCLI executable"
  
  if clirc <> 0 then do
    clirc = "CSMCLI RC" clirc ||":"
    /* Add error info line from error or output stream */
    if err.0 > 0 then clirc = clirc strip(err.1)
    else if out.0 > 0 then clirc = clirc strip(out.1)
  end
  numlines = out.0
  if numlines > 0 then do
    /* parse only last 5 lines for error codes */
    if numlines > 4 then tail = numlines - 4
    else tail = 1
    do i=1 to tail
      if debug >= 9 then say LOGD(9,"CLIOUT:" strip(out.i))
      /* Catch Error message code in last 5 lines and return last code  */
      if i >= tail then do
        if pos("IWN",out.i) > 0 then do
          outline = out.i
          do while outline <> ""
            parse var outline nextword outline
            if left(nextword,3) = "IWN" then do
              if right(nextword,1) = "E" then do
                if debug >=9 then say LOGD(9,"Found Error Msg:" nextword)
                clirc = strip(out.i)   /* Return full line with msg */
              end
            end
          end
        end
      end
    end
  end
  numlines = err.0
  if numlines > 0 then do
    do i=1 to numlines
      if debug >= 9 then say LOGD(9,"CLIERR:" strip(err.i))
      /* Catch Error message code in any line and return last code  */
      if pos("IWN",err.i) > 0 | pos("CMM",err.i) > 0 then do
        errline = err.i
        do while errline <> ""
          parse var errline nextword errline
          prefix = left(nextword,3)
          if prefix = "IWN" | prefix = "CMM" then do
            if right(nextword,1) = "E" then do
              if debug >=9 then say LOGD(9,"Found Error Msg:" nextword)
              clirc = strip(err.i)   /* Return full line with msg */
            end
          end
        end
      end
    end
  end
  if debug >=9 then say LOGD(9,"RC:" clirc)
  return clirc

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Reset Global Session variables (e.g. prior new CSMCLI queries)          -*/
/*---------------------------------------------------------------------------*/
RESETGLOBALS:
  /* Reset global Session variables to keep latest info from last query */
  GSname = "" /* Session Name                        */
  GSstate= "" /* Session State                       */
  GSrp   = "" /* Specific Role Pair if applicable    */
  GShost = "" /* Session active Host                 */
  GSrecov= "" /* Recoverability of Session/Rolepair  */
  GSprog = "" /* Progress of Rolepair                */
  GScpset= "" /* Qty of Copy Sets in Session         */
  GTid   = "" /* Task ID                             */
  GTname = "" /* Task name                           */
  GTstate= "" /* Task Stauts                         */
  GTlrt  = "" /* Task last run time                  */
  GTmsg  = "" /* Task Message                        */
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Prepare system environment for script execution.                        -*/
/*- It verifies whether the platform is supported by the script and if so   -*/
/*- it prepares the environment for execution.                              -*/
/*- Return codes:                                                           -*/
/*- 0     : Preparation completed successfully                              -*/
/*- ErrMsg: Message describing the problem                                  -*/
/*---------------------------------------------------------------------------*/
PREPAREENV:
  /* Get Operating System */
  parse upper source osfull .
  os = left(osfull,3)
  if os = "TSO" then do
    /* Verify if USS syscalls are possible */
    address tso
    if syscalls('ON') > 3 then do
        myrc = "ERROR: Unable to establish the USS SYSCALL environment"
        return myrc
    end
  end
  else if os = "WIN" then do
    /* initialize environment variables for CSMCLI */
    if debug >= 9 then do
       say line
       say LOGD(9,"Following environment variables have been defined for" ,
           "System Calls on" osfull)
    end
    do i=1 to env.0
      parse var env.i envname "=" envvalue
      if envname = "PATH" then do
        /* extend default system path for CSMCLI */
        envvalue = value(envname,,'ENVIRONMENT') || ";" || envvalue
      end
      /* set environment variable for rexx execution*/
      call value envname, envvalue, 'ENVIRONMENT'
      if debug >= 9 then do
        say LOGD(9,envname"="||value(envname,,'ENVIRONMENT'))
        if i = env.0 then do
          say line
          say
        end
      end
    end
  end
  else do
    /* OS not supported */
    myrc = "ERROR: Unsupported Operating System found:" osfull
    return myrc
  end
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Create common prefix for messages                                       -*/
/*- Eg: LOGI(message)                                                       -*/
/*-     message: String to be formatted with prefix                         -*/
/*---------------------------------------------------------------------------*/
LOGI:
  parse arg mymsg
  /* Add timestamp as prefix to message */
  return time() || ":" mymsg

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Create common prefix for Step messages                                  -*/
/*- Eg: LOGS(stepnum,message)                                               -*/
/*-     stepnum: Step number to be used in prefix                           -*/
/*-     message: String to be formatted with prefix                         -*/
/*---------------------------------------------------------------------------*/
LOGS:
  parse arg mystep, mymsg
  /* Add timestamp and Step number as prefix to message */
  return time() || ": Step" mystep ||":" mymsg

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Create common prefix for debug messages                                 -*/
/*- Eg: LOGD(dbglvl,message)                                                -*/
/*-     dbgnum : Debug level to be used in prefix                           -*/
/*-     message: String to be formatted with prefix                         -*/
/*---------------------------------------------------------------------------*/
LOGD:
  parse arg lvl, mymsg
  /* Add timestamp and debug prefix to message */
  return time() || ": --debug("||lvl||"):" mymsg

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Calculate runtime and format to mm:ss.s based on provided start time    -*/
/*- Eg: call GETRUNTIME(starttime)                                          -*/
/*-     starttime: Start time saved with time('E') to use for calculation   -*/
/*---------------------------------------------------------------------------*/
GETRUNTIME:
  parse arg mystarttime
  if datatype(mystarttime) = "NUM" then do
    myruntime = time('E') - mystarttime
    mymin = myruntime % 60
    mysec = right(format(myruntime // 60,,1),4,'0')
    return mymin || ":" || mysec "(min:sec)"
  end
  return "??:?? (min:sec)"

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Wait x seconds, utilizing USS system call                               -*/
/*- Eg: call WAIT(time)                                                     -*/
/*-     time: Number of seconds to wait                                     -*/
/*---------------------------------------------------------------------------*/
WAIT:
  parse arg seconds
  if os = "TSO" then do
    address syscall
    'sleep (seconds)'
    address tso
  end
  else if os = "WIN" then do
    address SYSTEM "timeout" seconds
  end
  
  return 0

/*---------------------------------------------------------------------------*/
/*- SUBROUTINE                                                              -*/
/*-                                                                         -*/
/*- Get delay depending on given timeout. Returns -1 for invalid timeouts.  -*/
/*- Eg: call GETDELAY(timeout)                                              -*/
/*-     timeout: Overall timeout to calculate appropriate delay (0-3600 sec)-*/
/*---------------------------------------------------------------------------*/
GETDELAY:
  parse arg myto
  if datatype(myto) <> "NUM" then return -1
  if myto > 0 then do
    if      myto <= 30  then return 5          /*  5 s delay within 30 sec */
    else if myto <= 120 then return 10         /* 10 s delay within 2  min */
    else if myto <= 300 then return 20         /* 20 s delay within 5  min */
    else if myto <= 600 then return 30         /* 30 s delay within 10 min */
    else if myto <= 3600 then return 60        /* 60 s delay within 60 min */
    else return -1
  end
  return 0
