<%@page import="java.util.Date"%>
<%@page import="java.util.Locale"%>
<%@page import="java.util.Calendar"%>
<%@page import="org.icpc.tools.cds.CDSConfig"%>
<%@page import="org.icpc.tools.cds.ConfiguredContest"%>
<%@page import="org.icpc.tools.contest.model.internal.Contest"%>
<%@page import="org.icpc.tools.contest.model.IContest"%>
<% ConfiguredContest cc = (ConfiguredContest) request.getAttribute("cc");
   IContest contest = cc.getContest();
   String webRoot = "/contests/" + cc.getId(); %>
<html>
<head>
  <title>Countdown Control</title>
  <link rel="stylesheet" href="/cds.css"/>
  <link rel="icon" type="image/png" href="/favicon.png"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
</head>

<script>
var targetTime = 50.0;

function toString(seconds_left) {
   var days = parseInt(seconds_left / 86400);
   seconds_left = seconds_left % 86400;
   
   var hours = parseInt(seconds_left / 3600);
   seconds_left = seconds_left % 3600;
   
   var minutes = parseInt(seconds_left / 60);
   var seconds = parseInt(seconds_left % 60);
   
   var text = "";
   if (days > 0)
      text = days + "d ";
   
   if (hours < 10)
      text += "0" + hours;
   else
      text += hours;
   
   text += ":";
   if (minutes < 10)
      text += "0" + minutes;
   else
      text += minutes;
   
   text += ":";
   if (seconds < 10)
      text += "0" + seconds;
   else
      text += seconds;
   
   return text;
}

// update the tag with id "countdown" every 300ms
setInterval(function () {
   var countdown = document.getElementById("countdown");
   if (targetTime == null || targetTime == "") {
      countdown.innerHTML = "undefined";
      return;
   } else if (targetTime < 0) {
      countdown.innerHTML = toString(-targetTime) + " (paused)";
      return;
   }
   // find the amount of "seconds" between now and target
   var current_date = new Date().getTime() / 1000.0;
   var seconds_left = (targetTime - current_date);
   
   if (seconds_left < 0) {
      countdown.innerHTML = "Contest is started";
   } else {
      countdown.innerHTML = toString(seconds_left);
   }
}, 300);

function sendCommand(id, command) {
   document.getElementById(id).disabled = true;

   var xmlhttp = new XMLHttpRequest();
   xmlhttp.onreadystatechange = function() {
     document.getElementById("status").innerHTML = "";
     if (xmlhttp.readyState == 4) {
        var resp = xmlhttp.responseText;
        if (xmlhttp.status == 200) {
           if (resp == null || resp.trim().length == 0)
              targetTime = null;
           else
              targetTime = parseInt(resp) / 1000.0;
        } else
           document.getElementById("status").innerHTML = resp;
        document.getElementById(id).disabled = false;
     }
   }
   xmlhttp.timeout = 10000;
   xmlhttp.ontimeout = function () {
      document.getElementById("status").innerHTML = "Request timed out";
      document.getElementById(id).disabled = false;
   }
   xmlhttp.open("PUT", "<%= webRoot %>/countdown/" + command, true);
   xmlhttp.send();
}

function sendCountdownStatusCommand(checkbox, command) {
   document.getElementById(checkbox.id).disabled = true;

   var s = "";
   for (i = 1; i < command; i++)
  	  s += "-";
   
   if (checkbox.checked)
      s += "Y";
   else
      s += "N";
   
   for (i = command; i < 9; i++)
  	  s += "-";

   var xmlhttp = new XMLHttpRequest();
   xmlhttp.onreadystatechange = function() {
     document.getElementById("status").innerHTML = "";
     if (xmlhttp.readyState == 4) {
        if (xmlhttp.status == 200) {
           // do nothing
        } else
           document.getElementById("status").innerHTML = xmlhttp.responseText;
        document.getElementById(checkbox.id).disabled = false;
     }
   }
   xmlhttp.timeout = 10000;
   xmlhttp.ontimeout = function () {
      document.getElementById("status").innerHTML = "Request timed out";
      document.getElementById(checkbox.id).disabled = false;
   }
   xmlhttp.open("PUT", "<%= webRoot %>/statuschecks/" + s, true);
   xmlhttp.send();
}

function updateCountdown() {
   var xmlhttp = new XMLHttpRequest();
   xmlhttp.onreadystatechange = function() {
     document.getElementById("status").innerHTML = "";
     if (xmlhttp.readyState == 4) {
        var resp = xmlhttp.responseText;
        if (xmlhttp.status == 200) {
           if (resp == null || resp.trim().length == 0)
              targetTime = null;
           else
              targetTime = parseInt(resp) / 1000.0;
        } else
           document.getElementById("status").innerHTML = resp;
     }
   }
   xmlhttp.timeout = 10000;
   xmlhttp.ontimeout = function () {
      document.getElementById("status").innerHTML = "Request timed out";
   }
   xmlhttp.open("GET", "<%= webRoot %>/countdown/update", true);
   xmlhttp.send();
}

function updateCountdownStatus() {  
   var xmlhttp = new XMLHttpRequest();
   xmlhttp.onreadystatechange = function() {
     document.getElementById("status").innerHTML = "";
     if (xmlhttp.readyState == 4) {
        if (xmlhttp.status == 200) {
           var s = xmlhttp.responseText;
           for (i = 0; i < 9; i++) {
              if (s.charAt(i) == 'Y')
                 document.getElementById("s" + (i+1)).checked = true;
              else
                 document.getElementById("s" + (i+1)).checked = false;
           }
        } else
           document.getElementById("status").innerHTML = xmlhttp.responseText;
     }
   }
   xmlhttp.open("GET", "<%= webRoot %>/statuschecks", true);
   xmlhttp.send();
}

function showHide() {
   var e = document.getElementById("controls");
   if (e.style.display == null || e.style.display == "none")
      e.style.display = "block";
   else
      e.style.display = "none";
}

function updateInBackground() {
   document.getElementById("status").innerHTML = "Updating status...";
   document.getElementById("controls").style.display = "none";
   updateCountdown();
   updateCountdownStatus();
   
   setInterval(updateCountdown, 5000);
   setInterval(updateCountdownStatus, 5000);
}
</script>

<body onload="updateInBackground()">

<div id="navigation-header">
  <div id="navigation-cds"><%= contest.getFormalName() %> - Countdown Control (<%= ConfiguredContest.getUser(request) %>)</div>
</div>

<div id="main">
<p>
<a href="<%= webRoot %>">Overview</a> -
<a href="<%= webRoot %>/details">Details</a> -
<a href="<%= webRoot %>/orgs">Organizations</a> -
<a href="<%= webRoot %>/teams">Teams</a> -
<a href="<%= webRoot %>/submissions">Submissions</a> -
<a href="<%= webRoot %>/clarifications">Clarifications</a> -
<a href="<%= webRoot %>/scoreboard">Scoreboard</a> -
Countdown -
<a href="<%= webRoot %>/finalize">Finalize</a> -
<a href="<%= webRoot %>/awards">Awards</a> -
<a href="<%= webRoot %>/video/status">Video</a> -
<a href="<%= webRoot %>/reports">Reports</a>
</p>

<b><font size="+10"><span id="countdown">unknown</span></font></b>

<p/>

<button id="show" class="show" onclick="showHide()">Show / Hide Controls</button>

<div id="controls">

<h3>Countdown Control</h3>

<p/>
<button id="pause" onclick="sendCommand('pause', 'pause')">Pause</button>
<button id="resume" onclick="sendCommand('resume', 'resume')">Resume</button>
<button id="clear" onclick="sendCommand('clear', 'clear')">Clear</button>

<h3>Time Control</h3>
<p/>
You cannot change time in the final 30s before a contest starts.

<p/>
<table>
<tr><td>
<select id="timeSelect">
  <option value="0:00:01">1 second</option>
  <option value="0:00:05">5 seconds</option>
  <option value="0:00:15">15 seconds</option>
  <option value="0:00:30">30 seconds</option>
  <option value="0:01:00">1 minute</option>
  <option value="0:05:00">5 minutes</option>
  <option value="0:15:00">15 minutes</option>
  <option value="0:30:00">30 minutes</option>
  <option value="1:00:00">1 hour</option>
  <option value="2:00:00">2 hours</option>
</select>
</td><td>
<button id="set" onclick="var e = document.getElementById('timeSelect'); sendCommand('set', 'set: ' + e.options[e.selectedIndex].value)">Set</button>
</td><td>
<button id="add" onclick="var e = document.getElementById('timeSelect'); sendCommand('add', 'add: ' + e.options[e.selectedIndex].value)">Add</button>
</td><td>
<button id="remove" onclick="var e = document.getElementById('timeSelect'); sendCommand('remove', 'remove: ' + e.options[e.selectedIndex].value)">Remove</button>

</td></tr>
<tr><td>
<input type="text" id="timeSelect2" value="0:01:00">
</td><td>
<button id="set2" onclick="var e = document.getElementById('timeSelect2'); sendCommand('set', 'set: ' + e.value)">Set</button>
</td><td>
<button id="add2" onclick="var e = document.getElementById('timeSelect2'); sendCommand('add', 'add: ' + e.value)">Add</button>
</td><td>
<button id="remove3" onclick="var e = document.getElementById('timeSelect2'); sendCommand('remove', 'remove: ' + e.value)">Remove</button>
</td></tr></table>

<p/>

<h3>Contest Readiness</h3>

<table>
<tr><td>
<input type="checkbox" id="s1" onclick="sendCountdownStatusCommand(this, '1')">Security
</td><td>
<input type="checkbox" id="s4" onclick="sendCountdownStatusCommand(this, '4')">Judges
</td><td>
<input type="checkbox" id="s7" onclick="sendCountdownStatusCommand(this, '7')">Operations
</td></tr><tr><td>
<input type="checkbox" id="s2" onclick="sendCountdownStatusCommand(this, '2')">Sysops
</td><td>
<input type="checkbox" id="s5" onclick="sendCountdownStatusCommand(this, '5')">Network Control
</td><td>
<input type="checkbox" id="s8" onclick="sendCountdownStatusCommand(this, '8')">Executive Director
</td></tr><tr><td>
<input type="checkbox" id="s3" onclick="sendCountdownStatusCommand(this, '3')">Contest Control
</td><td>
<input type="checkbox" id="s6" onclick="sendCountdownStatusCommand(this, '6')">Marshalls
</td><td>
<input type="checkbox" id="s8" onclick="sendCountdownStatusCommand(this, '9')">Contest Director
</td></tr>
</table>

</div>
<p/>
<span id="status"></span>
</div>

</body>
</html>