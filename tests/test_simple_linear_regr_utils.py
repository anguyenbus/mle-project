import numpy as np

from src.simple_linear_regr_utils import (  # Assuming the code is in a file named model_file.py
    evaluate,
    generate_data,
)


def test_generate_data():
    X_train, y_train, X_test, y_test = generate_data()

    # Test if the returned data has the correct shapes
    assert X_train.shape == (422, 1)
    assert y_train.shape == (422, 1)
    assert X_test.shape == (20, 1)
    assert y_test.shape == (20, 1)

    # Test if the training and test sets have different data
    assert not np.array_equal(X_train, X_test)
    assert not np.array_equal(y_train, y_test)


def test_evaluate():
    # Create dummy model and data for testing the evaluation function
    class DummyModel:
        def __init__(self):
            self.W = 2.0
            self.b = 1.0

    X_train = np.array([[1.0], [2.0], [3.0]])
    y_train = np.array([[3.0], [5.0], [7.0]])
    y_predicted = np.array([[3.5], [5.5], [6.5]])

    # Test evaluation function
    dummy_model = DummyModel()
    evaluate(dummy_model, X_train, y_train, y_predicted)

    # In a real test case, you could capture the printed output and check it programmatically.
    # For simplicity, we are not checking the printed output in this example.
