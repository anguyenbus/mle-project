from src import SimpleLinearRegression, evaluate, generate_data

X_train, y_train, X_test, y_test = generate_data()
model = SimpleLinearRegression()
model.fit(X_train, y_train)
predicted = model.predict(X_test)
evaluate(model, X_test, y_test, predicted)
