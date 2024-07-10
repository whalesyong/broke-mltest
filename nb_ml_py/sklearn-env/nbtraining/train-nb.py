import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB

# Read the CSV file
df = pd.read_csv('synthetic_nb_dataset.csv')

# Split into features (X) and labels (y)
X = df['Text']
y = df['Category']

# Convert text to BoW representation
vectorizer = CountVectorizer(lowercase=True)
X = vectorizer.fit_transform(X)

# Split into training and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train the model
nb_model = MultinomialNB()
nb_model.fit(X_train, y_train)

# Evaluate the model
accuracy = nb_model.score(X_test, y_test)
print(f"Model accuracy: {accuracy:.2f}")


def predict_category(text, threshold=0.4):
    # Transform the input text to BoW representation
    X_new = vectorizer.transform([text])
     
    # Get probabilities for each category
    probabilities = nb_model.predict_proba(X_new)[0]
    
    # Create a dictionary of category probabilities
    category_probs = dict(zip(nb_model.classes_, probabilities))
    
    # Find the category with the highest probability
    predicted_category = max(category_probs, key=category_probs.get)
    max_prob = category_probs[predicted_category]
    
    # If the highest probability is below the threshold, return "Other"
    if max_prob < threshold:
        predicted_category = "Other"
    
    return predicted_category, category_probs

#test case
test_strings= ['''            
Stngarere Pte Ltg
 Cettar t BODY
 COTTON ON
 ORCHARD
 BODY toN ION Orchard. e82 Centre.
 1ON Orchard Shopins ng
 350
 *TAY Invoice 2006168720
 6ST Nunber : Value
 6335735-3- Price s0 sOFT HIGY W9ISsT NAUY PICOT $5.00% S
 cTe87-S5- 5.0 THE INUJSteLE CHEEK. ., WINDSURFER S
 $5.004
 603437-7 THE TNUISIB... CRIMSON RED HEARTS S
 $5.00%
 AODY- 3 FOR $10 AGED UNDIES -$5.00
 Sale total (includes s0.83 GST) $10.00
 EFT Paynent Visa s10.00
 Change $0.00
 Total no. of units: 3
 Your Cashier uas Riyatul Wirdani
 Card nuntber: 503000284442
 Points for this sale: 0
 Points Balance: 34
 02/742702000239
 Fri 14 Jun 2024 8:46PH POS742702
 Terninal 1D
 Trans No. Reg 02/747275
 THANK YOU Change FOR SHOPPING yDur ur refund stad. AT l Bnytine exclange COTTON ON policy BODY
 Curious Retain Visit Bbout cottonon. Receipt ou con/S9/cot for Returns tonanbody   
 Receiot o. 2626-1774-0406
 CARDHOLDER COPY
 14/06/2024
 Date : 20:46:42
 Time
 : *9**3472
 Card
 :00
 PAN SEQ.
 Pref. nane : :visaprem VISA fumdeb1t
 Card type
 Payment Payment method variant : : Visa visaprentundebit Contact less chip
 mode
''']


for test_string in test_strings:
    predicted_category, category_probs = predict_category(test_string)
    
    print(f"\nInput: {test_string}")
    print(f"Predicted category: {predicted_category}")
    print("Category probabilities:")
    for category, prob in category_probs.items():
        print(f"{category}: {prob:.2f}")