# CSM-Rexx-Collection


[![Build Status](https://app.travis-ci.com/IBM/CSM-Rexx-Collection.svg?branch=master)](https://app.travis-ci.com/IBM/CSM-Rexx-Collection)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/5903/badge)](https://bestpractices.coreinfrastructure.org/projects/5903)

## Scope

The purpose of this project is to provide Rexx examples to utilize IBM Copy Services Manager. Most examples focus on Rexx on IBM z, but some may be used also with other Rexx distributions on various platforms. 

---

# Rexx Collection overview

## Rexx-CSMCLI-4-Site-Practice-Example

The [Rexx-CSMCLI-4-Site-Practice-Example](https://github.com/IBM/CSM-Rexx-Collection/tree/master/Rexx-CSMCLI-4-Site-Practice-Example) provides a Rexx executable to create a Practice copy for DR tests in a 4 Site Metro Mirror - Global Mirror session. It is the script that is documented in the White Paper [IBM Copy Services Manager Session automation.](https://www.ibm.com/support/pages/ibm-copy-services-manager-session-automation)

## Rexx-CSMCLI-Wrapper

The [Rexx-CSMCLI-Wrapper](https://github.com/IBM/CSM-Rexx-Collection/tree/master/Rexx-CSMCLI-Wrapper)  program is a wrapper for the CSMCLI executable program. Its primary goal is to provide a reliable program return code, to enable automation an easy indication whether a CSMCLI command was completed successfully or has resulted in a warning or error message code. The CSMCLI executable itself will always return RC=0 if the command was accepted by the CSM server, independent of the execution result. That makes it difficult for external automation flows to validate whether the CSMCLI was successfull. This Rexx wrapper will parse the responses for Error or Warning messages returned by executed commands and consolidate the findings in a program exit code. It will return RC=0 only if the issued command was accepted and the execution did not result in any Errors or Warnings.

## Rexx-Framework-CSM-Rest-Api

The [z/OS Rexx framework for CSM Rest API](https://github.com/IBM/CSM-Rexx-Collection/tree/master/Rexx-Framework-CSM-Rest-Api) was developed to demonstrate the 
z/OS TSO Web Enablement Toolkit capabilities in a simplified manner for 
utilizing the IBM Copy Services Manager Rest API interface. It enables z 
System Programmers and Storage Administrators to interact with IBM Copy 
Services Manager from a z platform without installing the CSM CLI for z/OS. 

---

# Notes

- This repository has been configured with the [DCO bot](https://github.com/probot/dco) to simplify licensing with contributions.

- If you have any questions or issues you can create a new [issue here](https://github.com/IBM/CSM-Rexx-Collection/issues).

- Pull requests are very welcome! Make sure your patches are well tested.
  Ideally create a topic branch for every separate change you make. For
  example:
  
  1. Fork the repo
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request

---

# License

All source files must include a Copyright and License header. The SPDX license header is preferred because it can be easily scanned.

If you would like to see the detailed LICENSE click [here](LICENSE).

```text
#
# Copyright 2020- IBM Inc. All rights reserved
# SPDX-License-Identifier: Apache2.0
#
```

The examples in this project are licensed under the Apache License 2.0. 
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0  

It is a permissive license whose main conditions require preservation of 
copyright and license notices. Contributors provide an express grant of 
patent rights. Licensed works, modifications, and larger works may be 
distributed under different terms and without source code.  

The examples are provided for tutorial purposes only. A complete handling 
of error conditions has not been shown or attempted, and the programs have 
not been submitted to formal IBM testing. The programs are distributed on an 
'AS IS' basis without any warranties either expressed or implied.

Copyright IBM Corporation  2021
