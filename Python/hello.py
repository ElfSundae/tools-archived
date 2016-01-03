#-*- coding: UTF-8 -*-

def add(a, b = 0):
	return a+b;

filePath = "./hello.py";
file = open(filePath, "r");
for line in file:
	print line;
file.close();	

print "\n\n";

####
s = raw_input("input your age:");
if (s == ""):
	raise Exception("input must no be empty");

try:
	i = int(s);
except ValueError:
	print "Cannot be converted to an integer."		
except:
	print "Unknow exception";
else:
	print "You're %d %s" %i "years old";
finally:
	print "Goodbye!";