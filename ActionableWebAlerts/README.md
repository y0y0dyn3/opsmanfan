## A Simple Rest Monitor

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/blog-banner.png)

Web Service APIs are not only here to stay, they are ubiquitous and reaching further and further into your infrastructure. With the arrival of services like Rackspace Cloud Sites, Service Now, and SalesForce, your mission critical applications and services will often be dependent on a Web Service API. And in the event you are not using one of the endless list of SAAS/IAAS/Cloud services out there, you are likely using at least one internally written app or off the shelf software package that utilizes a Web API. This could include REpresentational State Transfer (REST), SOAP, XMLRPC, WSDL and others.

At my current employer, almost every (maybe ALL) internally written applications now have a Web Service API. The current favorite of course is REST. Some of the older systems use SOAP and XMLRPC. It is not an understatement to say that if these Web Services are not available, important pieces of Rackspace’s operations can grind to a halt.

And this presents an interesting problem when using Operations Manager. There is very little information on how to use it to monitor these types of services. Most information available on the topic comes to the same conclusion that I came to a couple of months ago. You must script a custom solution. [Most of them such as this Technet thread suggest using  MSXML2.xmlhttp.](https://social.technet.microsoft.com/Forums/systemcenter/en-US/10e7798a-bbe6-4798-93d6-2e655fa74973/monitor-a-web-service-in-scom-2007-r2?forum=operationsmanagergeneral) 

I did finally come across a [Technet thread](https://social.technet.microsoft.com/Forums/systemcenter/en-US/33c0f171-f70b-4979-bdab-cd990714d447/how-can-i-monitor-a-soap-response-with-scom-2007-r2?forum=operationsmanagergenerall) that was working towards the same solution we came up with, although they seem to have gotten stuck.

And what is this solution?

If you are running Operations Manager 2012 you have two possible alternatives to writing a custom script based monitor, the Web Application Availability Monitoring, and Web Application Transaction Monitoring (also available in SCOM 2007 R2) templates. Which you use depends on your requirements. If you need multiple steps and the ability to save things like access tokens, you must use the Transaction Monitoring option.

If, as in this example you can do everything in one step, Web Application Availability Monitoring may be your best choice. The target of this monitor is a part of [The Python Challenge](http://www.pythonchallenge.com). They have created an xmlrpc based phone book API for the challenge, and as it is publicly accessible, it is perfect for this demo.

So the First step is to open the Web Application Availability Monitoring wizard, then enter a name, description and destination management pack. Then you provide a friendly name and the URL for your target. http://www.pythonchallenge.com/pc/phonebook.php in this case.

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/3.jpg)




Select your Watcher Node/Pool/Location.

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/4v2.jpg)

And now for the important part,  select "Change Configuration".

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/5v2.jpg)

Now Select content match contains "555".  This guarantees that we get a content match with a proper response and an alert for this demo. In production, you would of course want to alert on the absence of correct response.

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/7.jpg)


Change the HTTP method to POST.


![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/8.jpg)


Enter your XML into the request body.  A good primer on on XMLRPC syntax can be found here.
 
\<?xml version="1.0"?>\
\<methodCall>\
\<methodName>\phone\</methodName>\
\<params>\
\<param>\
\<value>\
\<string>\Bert\</string>\
\</value>\
\</param>\
\<params>\
\</methodCall>

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/9.jpg)



Add the Content-Type HTTP Header.  Set it to application/XML.


![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/10.jpg)

And you are done.  Click Apply.

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/11.jpg)

Now we can see the results.  Hit Run Test.

![Image](https://raw.githubusercontent.com/y0y0dyn3/opsmanfan/master/simplerestmonitor/docs/12.jpg)


And we get a valid response from our Web Service!  You have just authored your first Web Service API monitor!




So are there any limitations to this method?  Yes.

The web templates (as of this writing) only support Head, Get and Post HTTP methods.  If the web API requires Put, Delete, or any others as some APIs do, you will have to script your solution.

If I need to hit an API for instrumentation purposes, say for something like alerting when <int>300</int> is greater than 300, Web Templates are not really up to the task. Anything that involves complex handling or comparisons of responses returned by a Web Service will still have to be a scripted solution.
