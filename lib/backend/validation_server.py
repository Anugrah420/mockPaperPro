# Comprehensive Accuracy Validator for Colab
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict
import sympy as sp
from sympy import symbols, solve, simplify, Eq, integrate, diff, limit, series
import re
import math
import threading
import uvicorn
from google.colab.output import eval_js

app = FastAPI(title="JEE Question Accuracy Validator")


class AccuracyRequest(BaseModel):
    question_text: str
    options: List[str]
    correct_answer_index: int
    subject: str
    topic: str
    difficulty: str


class AccuracyResponse(BaseModel):
    accuracy_score: float  # 0.0 - 1.0
    confidence_level: str  # high/medium/low
    validation_passed: List[str]
    validation_failed: List[str]
    mathematical_correctness: float
    conceptual_soundness: float
    option_plausibility: float
    detailed_feedback: Dict


class QuestionAccuracyValidator:
    def __init__(self):
        self.x, self.y, self.z = symbols("x y z")

    def calculate_accuracy(self, request: AccuracyRequest) -> AccuracyResponse:
        """Calculate overall question accuracy score (0.0 - 1.0)"""
        scores = []
        passed_tests = []
        failed_tests = []

        print(f"🎯 Calculating accuracy for {request.subject} question...")

        # 1. Mathematical Correctness (40% weight)
        math_score, math_passed, math_failed = self._validate_mathematical_correctness(
            request.question_text,
            request.options[request.correct_answer_index],
            request.subject,
        )
        scores.append(math_score * 0.4)
        passed_tests.extend(math_passed)
        failed_tests.extend(math_failed)

        # 2. Conceptual Soundness (30% weight)
        concept_score, concept_passed, concept_failed = (
            self._validate_conceptual_soundness(
                request.question_text, request.subject, request.topic
            )
        )
        scores.append(concept_score * 0.3)
        passed_tests.extend(concept_passed)
        failed_tests.extend(concept_failed)

        # 3. Option Plausibility (20% weight)
        option_score, option_passed, option_failed = self._validate_option_plausibility(
            request.options, request.correct_answer_index
        )
        scores.append(option_score * 0.2)
        passed_tests.extend(option_passed)
        failed_tests.extend(option_failed)

        # 4. Difficulty Appropriateness (10% weight)
        diff_score, diff_passed, diff_failed = self._validate_difficulty(
            request.question_text, request.difficulty, request.subject
        )
        scores.append(diff_score * 0.1)
        passed_tests.extend(diff_passed)
        failed_tests.extend(diff_failed)

        # Calculate final accuracy score
        accuracy_score = sum(scores)

        # Determine confidence level
        if accuracy_score >= 0.85:
            confidence = "high"
        elif accuracy_score >= 0.70:
            confidence = "medium"
        else:
            confidence = "low"

        return AccuracyResponse(
            accuracy_score=round(accuracy_score, 3),
            confidence_level=confidence,
            validation_passed=passed_tests,
            validation_failed=failed_tests,
            mathematical_correctness=round(math_score, 3),
            conceptual_soundness=round(concept_score, 3),
            option_plausibility=round(option_score, 3),
            detailed_feedback={
                "component_scores": {
                    "mathematical_correctness": round(math_score, 3),
                    "conceptual_soundness": round(concept_score, 3),
                    "option_plausibility": round(option_score, 3),
                    "difficulty_appropriateness": round(diff_score, 3),
                },
                "weighted_contribution": {
                    "mathematics": round(scores[0], 3),
                    "conceptual": round(scores[1], 3),
                    "options": round(scores[2], 3),
                    "difficulty": round(scores[3], 3),
                },
            },
        )

    def _validate_mathematical_correctness(
        self, question_text: str, correct_answer: str, subject: str
    ) -> tuple:
        """Validate mathematical accuracy (returns score, passed_tests, failed_tests)"""
        score = 1.0
        passed = []
        failed = []

        try:
            # Test 1: Equation parsing and solving
            equations = self._extract_equations(question_text)
            if equations:
                equation_score = self._validate_equations(equations, correct_answer)
                score *= equation_score
                if equation_score >= 0.8:
                    passed.append("Equation parsing and solving")
                else:
                    failed.append("Equation validation")
            else:
                # No equations found - check if this is expected
                if subject == "Mathematics" and any(
                    word in question_text for word in ["solve", "find", "calculate"]
                ):
                    failed.append("Mathematical question lacks equations")
                    score *= 0.6

            # Test 2: Mathematical expression validity
            expressions = self._extract_mathematical_expressions(question_text)
            valid_expressions = sum(
                1 for expr in expressions if self._is_valid_expression(expr)
            )
            expr_ratio = valid_expressions / len(expressions) if expressions else 1.0
            score *= expr_ratio

            if expr_ratio >= 0.8:
                passed.append("Mathematical expression validity")
            else:
                failed.append("Invalid mathematical expressions")

            # Test 3: Solution verification
            if equations and subject in ["Mathematics", "Physics"]:
                solution_score = self._verify_solution(equations, correct_answer)
                score *= solution_score
                if solution_score >= 0.9:
                    passed.append("Solution verification")
                else:
                    failed.append("Solution doesn't satisfy equations")

        except Exception as e:
            score = 0.3
            failed.append(f"Mathematical validation error: {str(e)}")

        return max(0.0, min(1.0, score)), passed, failed

    def _validate_conceptual_soundness(
        self, question_text: str, subject: str, topic: str
    ) -> tuple:
        """Validate conceptual accuracy"""
        score = 1.0
        passed = []
        failed = []

        # Test 1: Question clarity
        clarity_score = self._calculate_clarity_score(question_text)
        score *= clarity_score
        if clarity_score >= 0.8:
            passed.append("Question clarity")
        else:
            failed.append("Unclear question phrasing")

        # Test 2: Subject relevance
        relevance_score = self._check_subject_relevance(question_text, subject, topic)
        score *= relevance_score
        if relevance_score >= 0.9:
            passed.append("Subject relevance")
        else:
            failed.append("Question doesn't match subject/topic")

        # Test 3: Logical consistency
        logic_score = self._check_logical_consistency(question_text)
        score *= logic_score
        if logic_score >= 0.9:
            passed.append("Logical consistency")
        else:
            failed.append("Logical inconsistencies detected")

        return max(0.0, min(1.0, score)), passed, failed

    def _validate_option_plausibility(
        self, options: List[str], correct_index: int
    ) -> tuple:
        """Validate option quality"""
        score = 1.0
        passed = []
        failed = []

        # Test 1: Option uniqueness
        unique_options = len(set(options))
        uniqueness_score = unique_options / len(options)
        score *= uniqueness_score
        if uniqueness_score == 1.0:
            passed.append("Option uniqueness")
        else:
            failed.append("Duplicate options found")

        # Test 2: Option length consistency
        lengths = [len(opt.strip()) for opt in options]
        avg_length = sum(lengths) / len(lengths)
        length_variance = sum((l - avg_length) ** 2 for l in lengths) / len(lengths)
        length_score = 1.0 - min(length_variance / 100, 0.5)  # Penalize high variance
        score *= length_score
        if length_score >= 0.9:
            passed.append("Option length consistency")
        else:
            failed.append("Inconsistent option lengths")

        # Test 3: Correct answer plausibility
        correct_option = options[correct_index]
        plausibility_score = self._check_answer_plausibility(correct_option, options)
        score *= plausibility_score
        if plausibility_score >= 0.8:
            passed.append("Correct answer plausibility")
        else:
            failed.append("Correct answer seems implausible")

        return max(0.0, min(1.0, score)), passed, failed

    def _validate_difficulty(
        self, question_text: str, difficulty: str, subject: str
    ) -> tuple:
        """Validate difficulty level appropriateness"""
        score = 1.0
        passed = []
        failed = []

        # Calculate complexity score
        complexity = self._calculate_complexity(question_text, subject)

        # Map to expected difficulty ranges
        expected_ranges = {"Easy": (0.0, 0.4), "Medium": (0.3, 0.7), "Hard": (0.6, 1.0)}

        min_expected, max_expected = expected_ranges.get(difficulty, (0.0, 1.0))

        if min_expected <= complexity <= max_expected:
            score = 0.9
            passed.append("Difficulty level appropriate")
        else:
            score = 0.5
            failed.append(
                f"Question complexity ({complexity:.2f}) doesn't match {difficulty} level"
            )

        return score, passed, failed

    # Helper methods
    def _extract_equations(self, text: str) -> List[str]:
        """Extract equations from text"""
        pattern = r"([a-zA-Z][a-zA-Z0-9]*\s*[=≠≈<>≤≥]\s*[^?\.]+)"
        return re.findall(pattern, text)

    def _extract_mathematical_expressions(self, text: str) -> List[str]:
        """Extract mathematical expressions"""
        expressions = []
        # Equations
        expressions.extend(self._extract_equations(text))
        # Integrals
        expressions.extend(re.findall(r"∫[^?]+d[a-zA-Z]", text))
        # Derivatives
        expressions.extend(re.findall(r"d[a-zA-Z]/d[a-zA-Z]", text))
        return expressions

    def _is_valid_expression(self, expression: str) -> bool:
        """Check if mathematical expression is valid"""
        try:
            if "=" in expression:
                lhs, rhs = expression.split("=", 1)
                sp.sympify(lhs.strip())
                sp.sympify(rhs.strip())
            else:
                sp.sympify(expression)
            return True
        except:
            return False

    def _validate_equations(self, equations: List[str], correct_answer: str) -> float:
        """Validate equations and solutions"""
        try:
            correct_val = sp.sympify(correct_answer)
            valid_count = 0

            for eq in equations:
                if "=" in eq:
                    lhs, rhs = eq.split("=", 1)
                    lhs_expr = sp.sympify(lhs.strip())
                    rhs_expr = sp.sympify(rhs.strip())

                    # Check if correct answer satisfies equation
                    lhs_val = lhs_expr.subs(self.x, correct_val)
                    rhs_val = rhs_expr.subs(self.x, correct_val)

                    if abs(float(lhs_val - rhs_val)) < 1e-10:
                        valid_count += 1

            return valid_count / len(equations) if equations else 1.0
        except:
            return 0.5

    def _verify_solution(self, equations: List[str], correct_answer: str) -> float:
        """Verify solution satisfies equations"""
        return self._validate_equations(equations, correct_answer)

    def _calculate_clarity_score(self, text: str) -> float:
        """Calculate question clarity score"""
        words = text.split()
        sentences = [s for s in text.split(".") if s.strip()]

        if len(words) < 10 or len(sentences) == 0:
            return 0.5

        # Sentence length penalty
        avg_sentence_len = len(words) / len(sentences)
        if avg_sentence_len > 25:
            clarity = 0.6
        elif avg_sentence_len > 15:
            clarity = 0.8
        else:
            clarity = 0.9

        # Question mark check
        if not text.strip().endswith("?"):
            clarity *= 0.8

        return clarity

    def _check_subject_relevance(self, text: str, subject: str, topic: str) -> float:
        """Check if question matches subject and topic"""
        subject_keywords = {
            "Mathematics": [
                "calculate",
                "solve",
                "find",
                "equation",
                "integral",
                "derivative",
            ],
            "Physics": ["force", "energy", "velocity", "acceleration", "field", "wave"],
            "Chemistry": [
                "reaction",
                "compound",
                "element",
                "bond",
                "mole",
                "solution",
            ],
        }

        keywords = subject_keywords.get(subject, [])
        matches = sum(1 for keyword in keywords if keyword in text.lower())

        return min(matches / 3, 1.0) if keywords else 0.7

    def _check_logical_consistency(self, text: str) -> float:
        """Check for logical inconsistencies"""
        # Check for contradictory statements
        contradictions = [
            ("maximum", "minimum"),
            ("increasing", "decreasing"),
            ("positive", "negative"),
        ]

        for term1, term2 in contradictions:
            if term1 in text.lower() and term2 in text.lower():
                return 0.3

        return 0.9

    def _check_answer_plausibility(
        self, correct_answer: str, all_options: List[str]
    ) -> float:
        """Check if correct answer seems plausible among options"""
        if not correct_answer.strip():
            return 0.1

        # Check if correct answer is significantly different from others
        if len(set(all_options)) == len(all_options):
            return 0.9

        return 0.7

    def _calculate_complexity(self, text: str, subject: str) -> float:
        """Calculate question complexity score"""
        complexity = 0.0

        # Length factor
        word_count = len(text.split())
        complexity += min(word_count / 100, 0.3)

        # Mathematical complexity
        math_expressions = self._extract_mathematical_expressions(text)
        complexity += min(len(math_expressions) / 5, 0.4)

        # Technical terms
        technical_terms = ["integral", "derivative", "matrix", "vector", "probability"]
        tech_count = sum(1 for term in technical_terms if term in text.lower())
        complexity += min(tech_count / 3, 0.3)

        return min(complexity, 1.0)


# Initialize validator
validator = QuestionAccuracyValidator()


@app.post("/check-accuracy", response_model=AccuracyResponse)
async def check_accuracy(request: AccuracyRequest):
    """Check how accurate/correct a question is"""
    return validator.calculate_accuracy(request)


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Question Accuracy Validator"}


# Test endpoint with sample questions
@app.get("/test-samples")
async def test_samples():
    samples = [
        {
            "question_text": "Solve for x: 2x + 5 = 13",
            "options": ["4", "5", "6", "7"],
            "correct_answer_index": 0,
            "subject": "Mathematics",
            "topic": "Algebra",
            "difficulty": "Easy",
        },
        {
            "question_text": "Find the derivative of x² with respect to x",
            "options": ["2x", "x", "2", "x²"],
            "correct_answer_index": 0,
            "subject": "Mathematics",
            "topic": "Calculus",
            "difficulty": "Easy",
        },
    ]

    results = []
    for sample in samples:
        request = AccuracyRequest(**sample)
        result = validator.calculate_accuracy(request)
        results.append(
            {
                "question": sample["question_text"],
                "accuracy_score": result.accuracy_score,
                "confidence": result.confidence_level,
            }
        )

    return {"test_results": results}


# Start the server
print("🚀 Starting Accuracy Validator Server...")


def start_server():
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")


# Start in background thread
server_thread = threading.Thread(target=start_server, daemon=True)
server_thread.start()

# Wait for server to start
import time

time.sleep(3)

# Get Colab URL
colab_url = eval_js("google.colab.kernel.proxyPort(8000)")
print(f"📡 Server running at: {colab_url}")
print(f"🎯 Accuracy check: {colab_url}/check-accuracy")
print(f"🧪 Test samples: {colab_url}/test-samples")
print(f"❤️ Health check: {colab_url}/health")

print("\n" + "=" * 50)
print("READY TO VALIDATE QUESTION ACCURACY!")
print("Send POST requests to /check-accuracy with question data")
print("=" * 50)
