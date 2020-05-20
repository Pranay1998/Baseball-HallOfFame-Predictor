import csv
import copy

# Load libraries
import pandas as pd
from sklearn.tree import DecisionTreeClassifier # Import Decision Tree Classifier
from sklearn.model_selection import train_test_split # Import train_test_split function
from sklearn import metrics #Import scikit-learn metrics module for accuracy calculation  
from sklearn import tree
import pydotplus

# Load csv

data = []
with open('results.csv', newline='') as csvfile:
    csv_data = csv.reader(csvfile, delimiter=' ', quotechar='|')
    for row in csv_data:
        data.append(row[0].split(','))

sums = {}
missing = {}

for i,col in enumerate(data[0]):
    if i == 0 or i == len(data[0]) - 1:
        continue
    missingg = 0
    summ = 0
    for j in range(1,len(data)):
        if data[j][i] == '\\N':
            missingg += 1
        else:
            summ += float(data[j][i].replace("\"", ''))
    sums[col.replace("\"", '')] = summ
    missing[col.replace("\"", '')] = missingg
        

for_average = ['feature_WHIP']


for i in range(len(data)):
    data[i][0] = data[i][0].replace("\"", '')
    data[i][len(data[0])-1] = data[i][len(data[0])-1].replace("\"", '')
    if i == 0:
        for j in range(len(data[0])):
            data[i][j] = data[i][j].replace("\"", '')
        continue
    for j in range(1, len(data[0])-1):
        if data[0][j] in for_average:
            data[i][j] = sums[data[0][j]]/(len(data[1:]) - missing[data[0][j]])
        else:
            data[i][j] = float(data[i][j].replace("\"", '').replace('\\N','0'))

# decision tree
df = pd.DataFrame.from_records(data[1:], columns = data[0])
df.head()

feature_cols = data[0][1:len(data[0]) - 1]

x = df[feature_cols]
y = df.classification



for c in ["gini", "entropy"]:
    with open('g34_DT_' + c + '_accuracy.csv', 'w', newline='') as file, open('g34_DT_' + c + '_predictions.csv', 'w', newline='') as file2:
        writer = csv.writer(file)
        writer.writerow(['Dataset number', 'Accuracy'])
        writer2 = csv.writer(file2)
        writer2.writerow(['Iteration','Classification','Prediction'])
        accuracies = []
        for i in range(1,6):
            x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2)
        
            # Create Decision Tree classifer object
            clf = DecisionTreeClassifier(criterion=c)
        
            # Train Decision Tree Classifer
            clf = clf.fit(x_train,y_train)
            
            if i == 5:
                dot_data = tree.export_graphviz(clf, feature_names = feature_cols, class_names = clf.classes_)
                graph = pydotplus.graph_from_dot_data(dot_data)  
                graph.write_png("tree-" + c +".png")
        
            #Predict the response for test dataset
            y_pred = clf.predict(x_test)
            y_test2 = y_test.values
            
            accuracy = metrics.accuracy_score(y_test2, y_pred)
            
            writer.writerow([str(i), str(accuracy)])
            
            for j in range(len(y_pred)):
                writer2.writerow([str(i), y_test2[j], y_pred[j]])
                
            accuracies.append(accuracy)
            
            if i == 5:
                print(c + ' -')
                print('Accuracy: ' + str(accuracy))
                print('Conf. Matrix - ')
                print(metrics.confusion_matrix(y_test2, y_pred))
                print('F1 score - ' + str(metrics.f1_score(y_test2, y_pred, pos_label = 'Y')))
                print()
            
            
        print()
        print(c + " average accuracy: " + str(sum(accuracies)/len(accuracies)))
        print()
