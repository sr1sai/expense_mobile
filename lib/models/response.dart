class Response<T> {
  final bool status;
  final String message;
  final T? data;

  Response({required this.status, required this.message, required this.data});

  factory Response.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? dataParser,
  }) {
    return Response<T>(
      status: json['status'] == true,
      message: json['message'] ?? '',
      data: dataParser != null && json['data'] != null
          ? dataParser(json['data'])
          : json['data'] as T?,
    );
  }
}
