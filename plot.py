import csv
import matplotlib.pyplot as plt
import numpy as np

def convert_to_float (item):
	if item != '':
		return float(item)
	return None

def add(num, inc):
	return num + inc

def getAvgPop (data_list, max_pop):
	monitor_num = 0
	# map (lambda x: float(x), current_row)
	avg_pop = []

	for row in data_list:
		index = (monitor_num % 4)
		current_pop = int(row[3])
		max_pop[index] += current_pop
		monitor_num += 1


	print max_pop
	# avg_pop = map(lambda pop: pop/365, max_pop)
	avg_pop = map(calc_annual_avg, max_pop)
	return avg_pop

def curve_fit(xvals,yvals):
	points = np.linspace(-0.3,0.5,100)
	curve = np.poly1d(np.polyfit(xvals,yvals10yr,2))
	plt.plot(xvals,yvals,"bo",points,curve(points),"-g")

	plt.ylabel('Max Pop in Year 10')
	plt.xlabel("pH Tolerance")
	plt.show()
	return

def make_labels (val):
	if (val > 0): 
		return "+" + str(val)
	return str(val)

def draw_hist (xlabels, yvals):
	fig,sub = plt.subplots()
	xvals = np.arange(len(xlabels))
	# yvals5yr = [y[0] for y in yvals]
	# yvals10yr = [y[-1] for y in yvals]
	# width = 0.8/len(yvals[1])
	width = 1.0/len(yvals)
	e = (3, 5, 12, 13, 30, 50)
	x_width = 0
	plt.yscale('linear')
	sub.set_xticks(xvals + 0.5)
	sub.set_xticklabels(xlabels)
	# sub.bar(xvals, yvals5yr, width, color = 'g', yerr = e)
	# sub.bar(xvals+width, yvals10yr, width, color = 'b')
	colors = ['g','y','r','m','c']

	for index,y in enumerate(yvals):
		sub.bar(xvals + x_width, y, width, color = colors[index])
		x_width += width

	plt.show()
	return

def getFromBS (data_reader):
	data = open("test.csv", "rb")
	data_reader = csv.reader(data)
	data_table = []
	xvals = []		#values to be plotted on the x-axis
	yvals = []		#values to be plotted on the y-axis
	run_data = [] 	#data for individual runs
	current_row = data_reader.next()
	while current_row[0] != "ph_tolerance":
		var = data_reader.next()
		if len(var) > 0:
			current_row = var

	xvals = map(convert_to_float, current_row[1:]) #str to float
	xvals = np.array(xvals) 	                   #list to array
	xlabels = map(make_labels,xvals)

	print xvals


	while current_row[0] != "[initial & final values]":	
		var = data_reader.next()
		if len(var) > 0:
			current_row = var

	for row in data_reader:
		data_table.append(row)

	for row in data_table:
		for val in row:
			if len(val) > 0:
				run_data = val.split()
				run_data[0] = run_data[0][1:]
				run_data[-1] = run_data[-1][:-1]
				yvals.append(map(convert_to_float, run_data))
			run_data = []

	# print yvals
	# print yvals5yr
	# print yvals10yr

	# curve_fit(xvals,yvals10yr)
	#draw_hist(xlabels,yvals)
	return

data = open("phSim01.csv", "rb")
data_reader = csv.reader(data)
data_table = {}
xvals = []		#values to be plotted on the x-axis
yvals = []		#values to be plotted on the y-axis
run_data = [] 	#data for individual runs

for row in data_reader:
	monitor_num = convert_to_float(row[1])
	monitor_pop = convert_to_float(row[3])
	if data_table.has_key(monitor_num):
		if data_table[monitor_num][2] < monitor_pop:
			data_table[monitor_num] = map(convert_to_float,row[1:])
	else:
		data_table[monitor_num] = map(convert_to_float,row[1:])

for val in data_table:
	yvals.append (data_table[val][3])

draw_hist([0.0],yvals[5:])


