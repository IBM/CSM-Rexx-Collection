# Rexx-CSMCLI-4-Site-Practice-Example

The Rexx-CSMCLI-4-Site-Practice-Example provides a template program how the IBM Copy Services Manager Command Line Interface (CSMCLI) installed on z/OS (USS) can be utilized to automate CSM actions. 
It uses the CSMCLI to create a consistent practice copy on 4th site of a four site replication topology with a CSM MM-GM-GC 4-site session.

For more details on the script workflow, please refer to following IBM White Paper:

- [IBM Copy Services Manager Session automation](https://www.ibm.com/support/pages/ibm-copy-services-manager-session-automation)

---

## Process steps used by the program

The program will try to create the practice copy when certain pre-check criteria are fulfilled:

- GM Role Pair must be Prepared

- GC Role Pair must be Preparing with a progress of at least xx % (xx is 
  customizable)  

If the creation of the practice copy is successful, it will try to restart only GM and enable the Practice Copy on the D volumes (H4). If the GM start fails, it will exit with a Warning RC=4.  

If the creation of the practice copy fails, it will try to restart GM and the cascaded GC of the session to minimize replication impact by the failed practice copy. Prior restart, it will verify the state of the session and might issue a Stop command to either the GM or GC role pair to ensure the session and all pairs are in a state to allow a proper restart. The script will exit with an error RC=8 if the restart was successful, otherwise with RC=12 if restart was not successful and replication is still impacted.  

Following are the executed steps:  

1) Check for Prepared state of H1-J3 pairs in session and Preparing 
   State of H3-H4 pairs in cascaded GC role pair with progress >= xx %) 

2) Suspend H1-H3 (GM leg) of session and wait until suspended 

3) FailoverH3 of session and wait until completed. 
   Wait for previous Suspended (Partially) state and check H1-H3 
   is recoverable and all H1-H3 pairs are Target Available 

4) Suspend cascaded GC of H3-H4 and wait until Suspended 

5) StartGM H1-H3 (GM leg) of session to minimize GM RPO impact 
   Wait for Prepared state of all H1-H3 pairs 

6) Failover cascaded GC of H3-H4 and wait until Target Available 
   Check that H3-H4 is recoverable  

If there are errors in step 1-5 or if an optional task is executed, 
the program will try to restore original GM and cascaded GC replication. 

## Optional Input Parameters

- **acsm=addr**: 
  Hostname or IP address of CSM server having the Active role. 
  This will overwrite the defined 'actcsm' value of the script. 
- **sess=*name***: 
  Name of the 4-site session to be used. 
  This will overwrite the defined 'deffsess' value of the script. 
  Name is case sensitive and single/double quotes must be used 
  if it contains spaces. Either session name is required.
- **task=*name***: 
  Name of the 4-site session scheduled task to be used instead 
  of script steps 1-5 (Optional). Script will then run the task, 
  monitor its completion, and restore replication in case of task 
  error. Name is case sensitive and single/double quotes must be 
  used if it contains spaces. 
- **pchk=*off***: 
  This will disable the Pre-Checks of the script (step 0). It 
  can be used if proper pre-checks are included in a given task. 
- **dbug=*lvl***: 
  This will set the debug level of the script. It can be used to 
  increase output details in case of unexpected errors. 
  Supported levels are 0 (default), 2 and 9 

## Return Codes

The program has following overall return codes: 

- 0: Practice Copy was created and GM is back in Prepared state 
- 4: Practice Copy was created, but GM could not be restarted within timeout 
- 8: Practice Copy creation failed, but previous replication was restarted 
- 12: Precheck error or practice copy as well as replication restart failed 
- 16: System environment for script cannot be established or missing parms 

## Runtime Environment

The Rexx program can be executed either on a Windows Platform or on z/OS (TSO & Batch). The platform where it is executed needs to have a Rexx interpreter in place and the CSMCLI needs to be installed with an existing authentication properties file for the CSM user. The location of the authentication properties file can be declared in the program with the environment parameter for HOME.  
The program was tested on z/OS with embedded Rexx interpreter as well as on Windows with [Regina Rexx](https://regina-rexx.sourceforge.io/) installed. A different Rexx interpreter on Windows might require adoptions in the script for system specific functions (e.g. reading and setting environment variables for the CSMCLI).

Other platforms are not supported at this time.

## Execution via JCL

On z/OS, the Rexx program can be executed via Job Control Language, for example to be scheduled in batch processing. Following JCL example shows how to execute the program and pass execution parameters:

```
//* Jobcard               
//* Jobcard               
//*******************************************************************/
//* Run the REXX program as specified below                            
//*******************************************************************/
//STEPTSO  EXEC PGM=IKJEFT01                                          
//SYSEXEC  DD DISP=SHR,DSN=#HLQ.CSM.CNTL                           
//SYSOUT   DD SYSOUT=*                                                
//SYSPRINT DD SYSOUT=*                                                
//SYSTSPRT DD SYSOUT=*                                                
//SYSTSIN  DD *                                                       
 PROFILE NOPREFIX                                                     
 %CL3PRACD                        -                                   
    acsm=mycsm.domain.com         -                                   
    sess='My MmGmGc'              -                                   
    task=''                                                           
/*                                                                    
//                                                                    
```

You need to update the Job card, SYSEXEC dataset and member name accordingly. The Rexx program execution parameters can be defined in the SYSTSIN DD statement as shown in this exampple. Make sure to concatenate multiple parameter lines with the program member name line by using the dash ‘-‘.

---

Copyright information and disclaimer
====================================

This example is licensed under the Apache License 2.0.  You may 
obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0  

It is a permissive license whose main conditions require preservation of 
copyright and license notices. Contributors provide an express grant of 
patent rights. Licensed works, modifications, and larger works may be 
distributed under different terms and without source code.  

The example is provided for tutorial purposes only. A complete handling 
of error conditions has not been shown or attempted, and this program has 
not been submitted to formal IBM testing. This program is distributed on an 
'AS IS' basis without any warranties either expressed or implied.

Copyright IBM Corporation  2021
