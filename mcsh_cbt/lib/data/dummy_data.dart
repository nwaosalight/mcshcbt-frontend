import '../models/exam.dart';
import '../models/student.dart';
import '../models/question.dart';

class DummyData {
  static final List<Exam> exams = [
    Exam(
      subject: "Mathematics",
      questionLen: 3,
      questions: [
        Question(
          label: "What is 2 + 2?",
          options: ["2", "4", "6", "8"],
          images: [],
        ),
        Question(
          label: "Solve for x: 3x + 5 = 14",
          options: ["x = 3", "x = 4", "x = 5", "x = 6"],
          images: ["https://example.com/equation-image1.png"],
        ),
        Question(
          label: "Identify the shape of the given figure",
          options:   ["Circle", "Triangle", "Square", "Rectangle"],
          images: ["https://example.com/shape-image1.png", "https://example.com/shape-image2.png"],
        ),
      ],
    ),
    Exam(
      subject: "English",
      questionLen: 2,
      questions: [
        Question(
          label: "What is the past tense of 'run'?",
          options: ["ran", "runned", "running", "runs"],
          images: [],
        ),
        Question(
          label: "Which word is a noun?",
          options: ["quickly", "beautiful", "house", "running"],
          images: [],
        ),
      ],
    ),
  ];

  static final List<Student> students = [
    Student(
      id: "ST001",
      name: "John Doe",
      grade: "Grade 10",
      examResults: [
        ExamResult(
          examId: "MATH001",
          subject: "Mathematics",
          score: 85,
          totalQuestions: 100,
          dateTaken: DateTime(2024, 1, 15),
        ),
      ],
    ),
    Student(
      id: "ST002",
      name: "Jane Smith",
      grade: "Grade 10",
      examResults: [
        ExamResult(
          examId: "MATH001",
          subject: "Mathematics",
          score: 92,
          totalQuestions: 100,
          dateTaken: DateTime(2024, 1, 15),
        ),
      ],
    ),
  ];

  static Student? authenticateStudent(String id, String password, String grade) {
    // In a real app, this would check against a secure database
    // For now, we'll just check if the student exists in our dummy data
    try {
      return students.firstWhere(
        (student) => student.id == id && student.grade == grade,
      );
    } catch (e) {
      return null;
    }
  }

  static List<Exam> getExamsForGrade(String grade) {
    // In a real app, this would filter exams based on grade level
    // For now, we'll return all exams
    return exams;
  }
} 