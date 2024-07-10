import random
import csv

# Define Categories
categories = ['Food and Beverage', 'Groceries', 'Retail']


category_words = { 
    'Food and Beverage' : ['Lemonade',"espresso", "Penne", 'Beverage','Appetizer','Entree','Main course','Side dish','Salad','Soup','Pasta','Pizza','Burger','Sandwich','Steak','Chicken','Fish','Seafood','Vegetables','Stir-fry','Curry','Burrito','Taco','Nachos','Fajitas','Lasagna','Spaghetti','Mac and cheese','Sushi','Sashimi','Spring rolls','Dumplings','Fried rice','Noodles','bolognese', 'Ramen','Pho','Tom yum soup','Pad thai','Massaman curry','Vindaloo','Tikka masala','Enchiladas','Quesadilla','Burrito bowl','Poke bowl','Bibimbap','Bulgogi','Falafel','Hummus','Baba ghanoush','Moussaka','Gyros','Souvlaki','Cannoli',"McDonald's",'Restaurant','Meal', 'Lunch','Dinner','Breakfast','Heineken','Red Bull','Beer','Vege','Btl','Basil','Dine in','Takeout','Cheeseburger','latte','cappuccino','mocha',"Starbuck's"],        
    'Groceries' : ['Produce','beef', 'Meat','Dairy','Bread','Cereal','Fruits','Vegetables','Eggs','Milk','Cheese','Yogurt','Coffee','Tea','Sugar','Flour','Rice','Pasta','Canned food','Frozen food','Snacks','Condiments','Spices','Herbs','Cereal bar','Paper towels','Toilet paper','Laundry detergent','Dish soap','Garbage bags','Shopping cart','Grocery bag','Aisle','Supermarket','Store','Market','Pantry','Recipe','Ingredient','Shopping list','Checkout','Cashier',"Coupon",'Sale','Organic','Brand','Fresh','Pantry staples','Meal prep','Bakery','Deli','Seafood','Juice','Soda','Water','Cooking oil','Vinegar','Spreads ','Jam','Peanut Butter','Soup','Canned beans','Dried fruit','Nuts','Seeds','Oatmeal',"Granola",'Yogurt parfaits','Salad dressing',"Foil",'Plastic wrap','Aluminum foil','Wax paper','Food storage containers','Ziplock bags','Sponges','Dish cloths','Paper plates','Plastic cups','Aluminum foil pans','Microwaveable meals','Pet food','Paper napkins','Snacks ','Candy','Gum','Frozen ','Ice cream','Frozen vegetables','Frozen fruit','Batteries','Light bulbs','Paper towels' ,'Facial tissues','Trash bags','Gift cards','Express checkout','Self-checkout','Loyalty program','Reusable shopping bags','Cold Storage','Fairprice','NTUC',],        
    'Retail' : ['Mall','clothes', "shoes", "jewelry", 'Shirt','Pants','Dress','Skirt','Jeans','Jacket','Sweater','T-shirt','Shoes','Socks','Underwear','Bra','Hat','Scarf','Belt','Bag','Purse','Jewelry','Size','Fit','Color','Style','Trend','Material','Cotton','Linen','Wool','Denim','Leather','Cashmere','Casual','Formal','Dressy','Sporty','Vintage','Brand','Label','Coupon','Promotion','Inventory','Stock','Display','Shelf','Aisle','Fitting room','Customer service','Activewear','clothing','electronics','swimwear','retail',],    
}

# Generate synthetic documents

def generate_document(category, num_words = 20):
    words = []
    for _ in range(num_words):
        if random.random() < 0.7:
            words.append(random.choice(category_words[category]))
        else: 
            words.append(random.choice(sum(category_words.values(), [])))
    
    return ' '.join(words) 

num_documents = 2000
output_file = 'synthetic_nb_dataset.csv'


with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['Text', 'Category'])  # Write header
    
    for _ in range(num_documents):
        category = random.choice(categories)
        document = generate_document(category)
        csvwriter.writerow([document, category])

print(f"Generated {num_documents} documents and saved to {output_file}")