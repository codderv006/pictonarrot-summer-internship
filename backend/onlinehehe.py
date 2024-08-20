from flask import Flask, jsonify, request
import requests
from io import BytesIO
import ollama
import json

app = Flask(__name__)

def generate(model, prompt, images=None):
    stream = ollama.generate(
        model=model,
        prompt=prompt,
        images=images,
        stream=True
    )
    response = ""
    for chunk in stream:
        response += chunk['response']
    return response

@app.route("/generate_description/", methods=["GET"])
def generate_description():
    image_url = request.args.get('image_url')
    grade = request.args.get('grade')

    if not image_url:
        return jsonify({"error": "Image URL is required"}), 400
    if not grade:
        return jsonify({"error": "Grade is required"}), 400

    try:
        grade = int(grade)
    except ValueError:
        return jsonify({"error": "Grade must be an integer"}), 400

    prompt = (
        f'''You are a story writer for a children's book and you will be given the grade of a student. You need to analyze the image and generate a story based on the grade of the student. 
        Here are the most important instructions you need to follow regarding the number of words and the complexity of the story:
        - If the grade is between 0-4, the story should be strictly in 20 words with minimal complexity.
        - If the grade is between 4-8, the story should be strictly in 30 words with normal complexity.
        - If the grade is 8 or above, the story should strictly be in 50 words with higher complexity.
        
        Generate a story for grade {grade} based on the above instructions. Do not mention the grade in the story.
        '''
    )

    model = 'llava:latest'
    
    try:
        response = requests.get(image_url)
        response.raise_for_status()  
        
        image_file = BytesIO(response.content)

        story = generate(model, prompt, images=[image_file])

        prepositions_prompt = f"Given the story: \"{story}\", strictly generate an array of prepositions present in the story separated by a comma."
        prepositions = generate(model, prepositions_prompt)

        adjectives_prompt = f"Given the story: \"{story}\", strictly generate an array of adjectives present in the story separated by a comma."
        adjectives = generate(model, adjectives_prompt)
        
        noun_prompt = f"Given the story: \"{story}\", strictly generate an array of nouns present in the story separated by a comma."
        nouns = generate(model, noun_prompt)

        question_prompt = f'''Given the story: "{story}", generate  4 multiple choice questions based on the story, each with 4 options and the first option being the correct answer to the question.
        This is the example representation which should be strictly followed and don't give inverted commas
        {{
            "question1": {{
                "description": "This is question no 1",
                "options": ["correct answer to the question", "option2", "option3", "option4"]
            }},
            "question2": {{
                "description": "This is question no 2",
                "options": ["correct answer to the question", "option2", "option3", "option4"]
            }},
            "question3": {{
                "description": "This is question no 3",
                "options": ["correct answer to the question", "option2", "option3", "option4"]
            }},
            "question4": {{
                "description": "This is question no 4",
                "options": ["correct answer to the question", "option2", "option3", "option4"]
            }}
        }}'''
        questions = (generate(model, question_prompt))

        return jsonify({"story": story, "nouns": nouns, "prepositions": prepositions, "adjectives": adjectives, "questions": eval(questions)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
