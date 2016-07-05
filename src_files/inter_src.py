import csv

def convert_to_float (item):
	if item != '':
		return float(item)
	return None

def getNext (row_index, col_index, table):	
	row_index += 1
	while row_index < len(table):
		if table[row_index][col_index] != None:
			return (row_index,table[row_index][col_index])
		row_index += 1

def update_file (filename):
	data = open(filename, "rU")
	data_reader = csv.reader(data, dialect = "excel")
	data_table = []
	index = 0

	for row in data_reader:
		entry = map(convert_to_float,row) #converts all items to floats
		data_table.append(entry)

	data.close()

	#searches the table row by row and fills in any missing values
	while index < len(data_table):
		row = data_table[index]
		for col_index,val in enumerate(row): #gets the index position and value respectively for each entry in the array
			if val == None:
				prev_val = data_table[index - 1][col_index]
				next_index,next_val = getNext(index,col_index,data_table) #gets next available data point
				
				inc = (next_val - prev_val)/(next_index - (index - 1))
				data_table[index][col_index] = prev_val + inc
		index += 1
				
	output = open(filename, "wb")
	data_writer = csv.writer(output)

	for row in data_table:
		data_writer.writerow(row)

folder_name = raw_input("Enter the save name as seen in NetLogo: ")

update_file("simulations/"+folder_name+"/input/parameters/ph-Table.csv")
update_file("simulations/"+folder_name+"/input/parameters/temp-Table.csv")
print "Interpolation complete!"