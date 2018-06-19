extends Node

# TASKS:
# [0] : ID
# [1] : TEXT
# [2] : TOTAL CHECKS
# [3] : CURRENT CHECKS
# [4] : OPTIONAL

var Tasks = []

func AddTask(Id, Text, Total_Checks, Optional = false):
	Tasks.append([Id, Text, Total_Checks, 0, Optional])
	print (Tasks)
	
func CheckTask(Id, Checks = 1):
	for t in Tasks:
		if (t[0] == Id):
			t[3] += Checks
	
	print ("NO TASK FOUND")
	return null
	return
	
func RetreiveTask(Id):
	for t in Tasks:
		if (t[0] == Id):
			return t 
	
	print ("NO TASK FOUND")
	return null

func AreAllCompleted(include_optional = false):
	var result = true
	
	for t in Tasks:
		if (include_optional or !t[4]):
			result = result and (t[3] >= t[2])
	
	return result

func AreAllOptionalCompleted():
	var result = true
	for t in Tasks:
		if (t[4]):
			result = result and (t[3] >= t[2])
	
	return result
	
func IsTaskCompleted(id):
	for t in Tasks:
		if (t[0] == id):
			if (t[3] >= t[2]):
				return true
			else:
				return false
	
	print ("NO TASK FOUND")
	return false

func TaskExists(id):
	for t in Tasks:
		if (t[0] == id):
			return true
	
	return false

func RemoveTask(id):
	for t in Tasks:
		if (t[0] == id):
			Tasks.erase(t)
			return true
	
	return false
	
	
func ClearAll():
	Tasks.clear()
	
func ClearCompleted(include_optional = false):
	var to_erase = []
	
	for t in Tasks:
		if (include_optional or !t[4]):
			if (t[3] >= t[2]):
				to_erase.append(t)
	
	for t in to_erase:
		Tasks.erase(t)

func ClearOptionals():
	var to_erase = []
	
	for t in Tasks:
		if (t[4]):
			if (t[3] >= t[2]):
				to_erase.append(t)
	
	for t in to_erase:
		Tasks.erase(t)
	
