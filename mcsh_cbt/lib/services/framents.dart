class GraphQLFragments {
  // User fragments
  static const String userFields = '''
    fragment UserFields on User {
      id
      uuid
      firstName
      lastName
      email
      role
      status
      profileImage
      phoneNumber
      lastLogin
      createdAt
      updatedAt
      fullName
    }
  ''';

  static const String userDetailFields = '''
    fragment UserDetailFields on User {
      ...UserFields
      teacherSubjects {
        ...SubjectFields
      }
      teacherGrades {
        ...GradeFields
      }
      notifications {
        ...NotificationFields
      }
    }
  ''';

  // Subject fragments
  static const String subjectFields = '''
    fragment SubjectFields on Subject {
      id
      uuid
      subjectCode
      name
      description
      isActive
      gradeId
      gradeName
      createdAt
      updatedAt
    }
  ''';

  static const String subjectDetailFields = '''
    fragment SubjectDetailFields on Subject {
      ...SubjectFields
      teachers {
        ...UserFields
      }
      exams {
        ...ExamFields
      }
    }
  ''';

  // Grade fragments
  static const String gradeFields = '''
    fragment GradeFields on Grade {
      id
      uuid
      name
      description
      academicYear
      isActive
      createdAt
      updatedAt
    }
  ''';

  static const String gradeDetailFields = '''
    fragment GradeDetailFields on Grade {
      ...GradeFields
      teachers {
        ...UserFields
      }
      students {
        ...UserFields
      }
      exams {
        ...ExamFields
      }
    }
  ''';

  // Exam fragments
  static const String examFields = '''
    fragment ExamFields on Exam {
      id
      uuid
      title
      description
      duration
      passmark
      shuffleQuestions
      allowReview
      showResults
      startDate
      endDate
      status
      instructions
      createdAt
      updatedAt
      questionCount
      totalPoints
    }
  ''';

  static const String examDetailFields = '''
    fragment ExamDetailFields on Exam {
      ...ExamFields
      subject {
        ...SubjectFields
      }
      grade {
        ...GradeFields
      }
      createdBy {
        ...UserFields
      }
      averageScore
      passRate
    }
  ''';

  // Question fragments
  static const String questionFields = '''
    fragment QuestionFields on Question {
      id
      uuid
      questionNumber
      text
      questionType
      options
      correctAnswer
      points
      difficultyLevel
      tags
      feedback
      image
      createdAt
      updatedAt
    }
  ''';

  // StudentExam fragments
  static const String studentExamFields = '''
    fragment StudentExamFields on StudentExam {
      id
      uuid
      startTime
      endTime
      timeSpent
      score
      isPassed
      status
      createdAt
      updatedAt
      progress
      remainingTime
      answeredCount
      markedCount
    }
  ''';

  static const String studentExamDetailFields = '''
    fragment StudentExamDetailFields on StudentExam {
      ...StudentExamFields
      student {
        ...UserFields
      }
      exam {
        ...ExamFields
      }
      answers {
        ...StudentAnswerFields
      }
    }
  ''';

  // StudentExamConnection fragment (new)
  static const String studentExamConnectionFields = '''
    fragment StudentExamConnectionFields on StudentExamConnection {
      edges {
        cursor
        node {
          ...StudentExamDetailFields
        }
      }
      pageInfo {
        ...PageInfoFields
      }
      totalCount
    }
  ''';

  // StudentAnswer fragments
  static const String studentAnswerFields = '''
    fragment StudentAnswerFields on StudentAnswer {
      id
      uuid
      selectedAnswer
      isCorrect
      isMarked
      timeTaken
      answeredAt
      createdAt
      updatedAt
    }
  ''';

  static const String studentAnswerDetailFields = '''
    fragment StudentAnswerDetailFields on StudentAnswer {
      ...StudentAnswerFields
      student {
        ...UserFields
      }
      question {
        ...QuestionFields
      }
      studentExam {
        ...StudentExamFields
      }
    }
  ''';

  // Notification fragments
  static const String notificationFields = '''
    fragment NotificationFields on Notification {
      id
      uuid
      title
      message
      type
      isRead
      createdAt
    }
  ''';

  // Error fragment
  static const String errorFields = '''
    fragment ErrorFields on Error {
      code
      message
      path
      details
    }
  ''';

  // PageInfo fragment
  static const String pageInfoFields = '''
    fragment PageInfoFields on PageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
  ''';

  // Combine all fragments for use in queries/mutations
  static String getAllFragments() {
    return '''
      $userFields
      $userDetailFields
      $subjectFields
      $subjectDetailFields
      $gradeFields
      $gradeDetailFields
      $examFields
      $examDetailFields
      $questionFields
      $studentExamFields
      $studentExamDetailFields
      $studentExamConnectionFields
      $studentAnswerFields
      $studentAnswerDetailFields
      $notificationFields
      $errorFields
      $pageInfoFields
    ''';
  }
}