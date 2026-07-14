# from fastapi import FastAPI

# app = FastAPI()


# @app.get("/")
# def read_root():
#     return {"status": "ready to practice ACT math"}


def main():
    phase = "launch"
    totalQuestions = 0
    print("Hello from act-math-study!")
    # loop phase checks
    if phase == "launch":
        print("This is where the launch screen should go.")  # Hand off to Nolan
        # Detect user engagement
        phase = "practice"
    if phase == "practice":
        totalQuestions += 30
        for i in totalQuestions:
            # put question gen logic in another file + import
            askQuestion()  # pull from queue?
            totalQuestions -= 1

        # question loop with increment


def askQuestion():
    print()


if __name__ == "__main__":
    main()
