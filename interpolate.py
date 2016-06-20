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

data = open("data/input_files/pH-Table.csv", "rb")
data_reader = csv.reader(data)
data_table = []
index = 0

for row in data_reader:
	entry = map(convert_to_float,row) #converts all items to floats
	data_table.append(entry)

data.close()

while index < len(data_table):
	row = data_table[index]
	if row[1] == None:
		prev_val = data_table[index - 1][1]
		next_index,next_val = getNext(index,1,data_table)
		inc = (next_val - prev_val)/(next_index - (index - 1))
		data_table[index][1] = prev_val + inc

	# if row[2] == None:
	# 	prev_val = data_table[index - 1][2]
	# 	next_index,next_val = getNext(index,2,data_table)
	# 	inc = (next_val - prev_val)/(next_index - (index - 1))
	# 	data_table[index][2] = prev_val + inc
	index += 1
			
output = open("interpolated.csv", "wb")
data_writer = csv.writer(output)

for row in data_table:
	data_writer.writerow(row)			
print data_table