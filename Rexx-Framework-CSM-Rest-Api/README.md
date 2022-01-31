----------------------------------------------

About the z/OS Rexx framework for CSM Rest API
==============================================

The z/OS Rexx framework for CSM Rest API was developed to demonstrate the 
z/OS TSO Web Enablement Toolkit capabilities in a simplified manner for 
utilizing the IBM Copy Services Manager Rest API interface. It enables z 
System Programmers and Storage Administrators to interact with IBM Copy 
Services Manager from a z platform without installing the CSM CLI for z/OS. 
The z/OS TSO Web Enablement Toolkit is available with z/OS 2\.2 or later and 
provides HTTP and JSON services that are callable through various program 
languages. For more information, please refer to: 

- https://www.ibm.com/docs/en/zos/2.2.0?topic=consider-zos-client-web-enablement-toolkit

The Rexx framework provides functions and procedures to utilize the web 
enablement toolkit services in Rexx. It re-uses Rexx examples from 
following sources:

- https://github.com/IBM/zOS-Client-Web-Enablement-Toolkit
- SYS1.SAMPLIB(HWTJSPRT) => Rexx template to print formatted JSON text

The framework does not only provide necessary HTTP request handling and 
JSON response parsing, but it also provides other additional features 
that greatly simplify the z/OS web enablement toolkit usage for CSM 
Rest API. For a generic usage description of the CSM Rest API, please 
refer to:

- https://www.ibm.com/docs/en/csm/6.3.1?topic=reference-csm-rest-api-documentation

----------------------------------------

Features supported by the Rexx framework
========================================

1. The Rexx framework supports automated  management of CSM server 
   credentials (and http request tokens) encrypted in flat text files or 
   datasets. Each framework user can utilize its own credentials file, which 
   is a customizable execution parameter. If no or invalid saved credentials 
   are found, the user will be prompted for actual CSM server credentials.  
   **Note:**  
   Depending on the execution environment of the Rexx, the password 
   prompt may occur with echo. Following are the rules for password prompts:  
   
   - If running in OMVS shell or ISPF environments, the password prompt will 
     be masked.
   - If the credentials will be prompted in an ISPF environment, it will be 
     done via a dynamic ISPF panel popup. The panel member (and dataset) will be 
     automatically created if not existing. This allows to prompt the password 
     without display. 
   - When running the Rexx in plain TSO environments, the password prompt 
     cannot be masked. 
   - If the credentials prompt is aborted or no valid credentials are 
     provided, an empty credential template file is created. You can specify 
     valid CSM user credentials in the file directly and they will be encrypted 
     during next Rexx execution using the same credentials file. 

2. The HTTP request wrapper function automatically manages all web 
   enablement toolkit tasks required to issue an HTTP request to a CSM server. 
   All requests are using the CSM recommended token based authentication method. 
   If no token is available or the last token is expired, the wrapper function 
   will request a new token from the CSM server with the provided CSM server 
   credentials.  

3. Existing JSON functions of the framework can be utilized to either print 
   a JSON formatted output of the response data, or to parse the JSON text for 
   specific entries and values.

4. An optional output USS file can be specified to save the HTTP response 
   data. This is required if you request to download a backup from the CSM 
   server, which will result in a binary octet-stream response and binary 
   stream data cannot be further parsed or displayed through the JSON 
   functions.

5. The Rexx framework is parameterized to a large extend and supports 
   various execution modes:  
   
   - Executable directly from ISPF or TSO panels
   - Executable from TSO shell
   - Executable from OMVS shell (and as such, also via external ssh 
     calls to OMVS if remote ssh login is configured)
   - Executable via a z/OS job

6. Static parameters for your environment can be hard coded in the Rexx. 
   Other parameters used more dynamically should be specified as execution 
   parameters, which will overwrite the hard coded parameter (default) 
   settings.

7. The default execution mode of the framework is to issue the specified or 
   hardcoded HTTP request and display the JSON formatted response. When using 
   the execution parameter **-u**, you can also dynamically specify and run any 
   defined and allowed framework CSM_ function of the Rexx. There are a couple 
   of example CSM_ functions contained in the Rexx to demonstrate usage of the 
   functions and procedures and how CSM response data can be parsed and 
   displayed. Examples include display of a CSM session, storage system or path
   overview, scheduled task overview, or to issue a CSM session command or 
   scheduled task command.

8. The main routine, as well as other functions of the Rexx framework, can 
   be modified or expanded as required for your needs. Some examples are 
   provided in the main function.  
   **The Rexx is provided "AS IS" without any warranty or support.**

------------------------------

Limitations and considerations
==============================

1. The Rexx framework contains code to support the SSL key type option with 
   PKCS11 Tokens or keyrings provided via the Security Facility (e.g. RACF). 
   Although these options can be configured via execution parameter (*-k*) or 
   variable (**g.cKeyRing**), their functionality was not fully tested. The SSL 
   key type option with a PKCS12 key database (*-k* or **g.cKeyDb**) and password 
   stash file (*-s* or **g.cDbStash**) is the tested option.

2. The Rexx framework contains code to support Basic Authentication setup 
   for HTTP requests. This authentication mode however is not utilized for CSM 
   server Rest API because **the preferred token based authentication method is 
   automatically configured** and managed through the HTTP request wrapper 
   function.

3. The HTTP response body is **by default translated from ASCII to EBCEDIC 
   (*A2E*)** to allow parsing of JSON text on the z platform. If stream data is 
   expected in the HTTP response, the body translation of the HTTP request 
   handle needs to be switched off first, before issuing the request. Otherwise 
   an output file receiving the binary data may not be usable. The 
   http_request() wrapper function of the framework automatically disables A2E 
   translation of the response body if it finds a '/download' pattern in the 
   request path. You can also force disabling the A2E translation via a 
   wrapper function parameter if necessary.

4. The **size of the data that can be received by the Rexx framework is 
   limited to 16 MB**. This may be sufficient to download CSM backup files, but 
   not for CSM PePackages. This limitation is based on Rexx variable limits, 
   which are used buffer the response data received by the web enablement 
   toolkit. There is no work around in Rexx to receive unlimited streams as 
   supported by the web enablement  toolkit when using non-Rexx 
   implementations supporting program exits.

------------------------------

How to use the Rexx framework:
==============================

Overview of encessary steps to use the Rexx framework. For more usage details 
and examples, please refer to the *zOS Rexx framework for CSM Rest API.pdf*:

1. Download the framework from github and install it for TSO or OMVS usage  
   
   - Upload and RECEIVE XMIT file into partitioned dataset for TSO usage
   - Upload Rexx framework as executable file to OMVS for OMVS usage

2. Prepare usage of the Rexx framework:  
   
   - Create the PKCS12 keystore file with public CSM server https certificate
   - Required and optional File definitions for the execution

3. Program execution parameters:  
   
   ```custom
   -h: Host URI with protocol, host, port to be used for the connection  
   -k: Key database file or keyring with certificate for HTTPS connections  
   -s: Stash file to access the key database file  
   -l: Label of certificate in PKCS12 key database  
   -u: Use specified internal CSM function (will ignore -r -p -d -f)  
   -r: Request type: GET, PUT, POST, DELETE, HEAD  
   -p: Full URI path to the requested service  
   -d: Data to send in request body, such as input parameter  
   -c: USS file or DSN(Mbr) to save CSM server credentials  
   -e: USS file or DSN(Mbr) with encryption key for server credentials  
   -i: Enable informative output (Default is disabled)  
   -v: Enable verbose output (Default is disabled)  
   -t: Optional Trace File for verbose connection output (Default Stdout)  
   -f: Filter for JSON root object entries to be displayed  
   -o: USS Output file to save response data (Required for Stream data)
   ```

4. Invokation example: 
   
   ```shell
   ./rxcsmapi.rexx -h "https://hostname:port" -k "/u/username/keystore.p12"
   -s "/u/username/keystore.sth" -l "certlabel" -c "/u/username/cred.txt" -e 
   "/u/username/cred.key" -i -r "POST" 
   -p "/CSM/web/sessions/<name>/backups/H1/<backupid>" 
   -d "cmd=Recover%20Backup" -f "msgTranslated","timestamp" 
   ```

5. Valid functions for the **-u** parameter (Mandatory parameters are **bold**):  
   
   - **CSM_SessOverview**(*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_SysOverview**(*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_PathOverview**(*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_TaskOverview**(*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_GetSysPaths**(**sys**,*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_GetSessCpSets**(**sess**,*cols*,*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_GetSessBackups**(**sess**,*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_GetSessCmd**(**sess**,*hdr*,*fmt*,*delim*,*sort*)
   - **CSM_RunSessCmd**(**sess,cmd**,*parm*)
   - **CSM_RunHaCmd**(**cmd**,*remoteserver*:*port*,*user*,*pwd*)
   - **CSM_RunTaskCmd**(**taskid,cmd**,*datetime*,*sync*)
   - **CSM_ShowTask**(**task**,*hdr*,*fmt*,*delim*)

6. Framework usage example in OMVS:  
   
   ```shell
   TLUTHER:/MCECEBC/u/tluther:> ./rxcsmapi.rexx -h https://csmserver:9559 
   -k /u/tluther/csmcerts.p12 -s /u/tluther/csmcerts.sth -l csmserver1 
   -c /u/tluther/cred.txt -e /u/tluther/cred.key -r "GET" -p "/CSM/web/system/ha"
   {
     "msg"              : "IWNR3048I",
     "resultText"       : "IWNR3048I [Dec 7, 2021 4:38:26 PM] The high availability status from server WINDOWS-PJ1KTM6 was successfully queried.",
     "islocalactive"    : true,
     "maxsupportedconnections": 1,
     "localhaport"      : 9561,
     "serverinfo"       : [],
     "inserts"          : [
       "WINDOWS-PJ1KTM6"
     ],
     "timestamp"        : 1638891506538
   }
   ```

------------------------------------

Copyright information and disclaimer
====================================

Like the z/OS Web Enablement toolkit is licensed under the Apache License 
2.0, this Rexx framework is licensed under the same conditions. You may 
obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0  

It is a permissive license whose main conditions require preservation of 
copyright and license notices. Contributors provide an express grant of 
patent rights. Licensed works, modifications, and larger works may be 
distributed under different terms and without source code.  

This framework is provided for tutorial purposes only. A complete handling 
of error conditions has not been shown or attempted, and this program has 
not been submitted to formal IBM testing. This program is distributed on an 
'AS IS' basis without any warranties either expressed or implied.

Copyright IBM Corporation  2021
