/// A functional result type representing either success (Ok) or failure (Err).
sealed class Result<T, E> {
  const Result();

  /// Returns true if the result is Ok.
  bool isOk() => this is Ok<T, E>;

  /// Returns true if the result is Err.
  bool isErr() => this is Err<T, E>;

  /// Gets the contained Ok value, throws if Err.
  T unwrap() {
    return switch (this) {
      Ok(value: final value) => value,
      Err() => throw Exception('Called unwrap on an Err value'),
    };
  }

  /// Gets the contained Err value, throws if Ok.
  E unwrapErr() {
    return switch (this) {
      Ok() => throw Exception('Called unwrapErr on an Ok value'),
      Err(error: final error) => error,
    };
  }

  /// Gets the contained Ok value or a default.
  T unwrapOr(T defaultValue) {
    return switch (this) {
      Ok(value: final value) => value,
      Err() => defaultValue,
    };
  }

  /// Transforms the contained value if Ok.
  Result<U, E> map<U>(U Function(T) fn) {
    return switch (this) {
      Ok(value: final value) => Ok(fn(value)),
      Err(error: final error) => Err(error),
    };
  }

  /// Transforms the contained error if Err.
  Result<T, F> mapErr<F>(F Function(E) fn) {
    return switch (this) {
      Ok(value: final value) => Ok(value),
      Err(error: final error) => Err(fn(error)),
    };
  }

  /// Chains another result-producing operation if Ok.
  Result<U, E> andThen<U>(Result<U, E> Function(T) fn) {
    return switch (this) {
      Ok(value: final value) => fn(value),
      Err(error: final error) => Err(error),
    };
  }

  /// Pattern matching for exhaustive handling.
  R match<R>({
    required R Function(T) ok,
    required R Function(E) err,
  }) {
    return switch (this) {
      Ok(value: final value) => ok(value),
      Err(error: final error) => err(error),
    };
  }
}

/// Success value
class Ok<T, E> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T, E> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// Error value
class Err<T, E> extends Result<T, E> {
  final E error;

  const Err(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T, E> && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Err($error)';
}