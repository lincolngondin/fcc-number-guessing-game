#!/bin/bash

# PSQL variable to access the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate the secret number
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

# ask for username
echo Enter your username:
read USERNAME

# search username in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
if [[ -z $USER_ID ]]
then
  echo Welcome, $USERNAME! It looks like this is your first time here.
  # insert the user in the database
  INSERT_RESULT=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  # get new user id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # get times played
  TIMES_PLAYED=$($PSQL "SELECT COUNT(user_id) FROM games WHERE user_id=$USER_ID")
  BEST_GAME_GUESSES=$($PSQL "SELECT min(guesses) FROM games WHERE user_id=$USER_ID")
  echo "Welcome back, $USERNAME! You have played $TIMES_PLAYED games, and your best game took $BEST_GAME_GUESSES guesses."
fi

RUNNING=1
GUESS_COUNT=0
echo Guess the secret number between 1 and 1000:
while (( $RUNNING ));
do
  read USER_GUESS
  IS_NUMBER=$(echo $USER_GUESS | sed 's/^[0-9]*$//')
  if [[ -z "$IS_NUMBER" ]]
  then
    # increment the guess count
    if (( USER_GUESS < SECRET_NUMBER ))
    then
      GUESS_COUNT=$((GUESS_COUNT+1))
      echo "It's higher than that, guess again:"
    elif (( USER_GUESS > SECRET_NUMBER ))
    then
      GUESS_COUNT=$((GUESS_COUNT+1))
      echo "It's lower than that, guess again:"
    else
      GUESS_COUNT=$((GUESS_COUNT+1))
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
      # insert the game in database
      INSERT_GAME=$($PSQL "INSERT INTO games (user_id, guesses) VALUES ($USER_ID, $GUESS_COUNT)")
      # stop running
      RUNNING=0
    fi
  else
    echo "That is not an integer, guess again:"
  fi
done