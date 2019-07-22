# Book Errata

A considerable amount of time was expended proofreading the book details.
Besides the author there were several other people who also looked for errors.
Sadly, not all errors were caught during production but not all.

This document describes the errors found.

## Errors

### Preface

Page IX, 4th paragraph, second line, should read:  
"spelled out in full. Thus, no abbreviated parameter names or positional parameters. This"

### Chapter 1 - Establishing a PowerShell Administrative Environment

Page 11 - small error in screen shots. they should not be different.
Page 12, 2nd Paragraph, penultimate line - the sentence should read:  "And for versions later than 1803, the
mechanism may change again."
And with the passage of time since the book was written, the mechanism has indeed changed again.

Page 15 - Step 15 should read SRV1, not SRV2

### Chapter 2 -Managing Windows Networking

Page 65/66 - Step 6 is not actually shown. The output (on page 66) is form step 7 not step 6.

### Chapter 4 - Managing Windows Storage

Page 134 - The code is fine in the book, but the GITHUB copy had an error in step 5 which is fixed.

### Chapter 12 - Managing Azure

Page 446, last paragraph in intro = this recipe does not check whether the RG and the SA are already created.
Page 447, step 2 - the text is wrong, only login to the Azure account
Page 447. step 5 - the name of the share should be $ShareName.





### Chapter 14 - Managing Performance and Usage

page 467 - step 9, second line - the Counter should be $Counter2

Page 471 - photo for step 9 is likewise incorrect in terms of counter name even though the output values are correct.

Page 471 - the lead in to the graphic for step 9, the server name cited should be HV1.

Page 479 - the values for LogFileFormat mentioned in the text are wrong and should be like this:
'''powershell
public enum LogFileFormat
{
    CommaSeparated = 0,
    TabSeparated = 1,
    Sql = 2,
    Binary = 3,
}
'''

Page 482 - graphic for step 2 is incorrect.

Page 493 - step 13. Error in getting CPU numbers
#          (Script updated too)
'''powershell
#this
$VMReport.VMCPU = $VM.CPUUsage
#should be
$VMReport.VMCPU = $VM.ProcessorCount


