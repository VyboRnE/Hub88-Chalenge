# TestTask

## [Hub88 Developer Challenge](https://github.com/coingaming/hub88-jnr)

This project is a demonstration of an Operator's "Wallet API" service, implemented using the Elixir Phoenix framework. Below are the details on how to set up, run, and test the application.

## Overview

This project implements a Wallet API that allows users to check their balance, place bets, and record wins. The API ensures proper validation of requests and handles user management seamlessly.

## Features

- **User Balance Check**: Returns the user's balance and creates a new user with an initial balance of 1000 EUR if they do not exist.
- **Betting**: Deducts a specified amount from the user's balance after validating the request.
- **Winning**: Increases the user's balance based on winnings while ensuring the bet transaction is valid and not closed.
- **Idempotency**: Ensures that transactions can be processed multiple times without unintended side effects.

## Installation and testing

1. **Clone the Repository**
2. **Run `mix setup` to install and setup dependencies**
3. **Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`**
4. **Test API through Postman (use http://localhost:4000/api endpoint)**

## API Endpoints

### User Balance

- **Endpoint**: `/api/user/balance`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "user": "username"
  }```

### Transaction Bet

- **Endpoint**: `/api/transaction/bet`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "user": "username",
    "amount": 100,
    "currency": "EUR",
    "transaction_uuid": "uuid",
  }```

### Transaction Win

- **Endpoint**: `/api/transaction/win`
- **Method**: `POST`
- **Request Body**:
  ```json
  {
    "user": "username",
    "amount": 100,
    "currency": "EUR",
    "transaction_uuid": "uuid",
    "reference_uuid": "reference_uuid"
  }```

### Testing
To run the test, use: `mix test` command.