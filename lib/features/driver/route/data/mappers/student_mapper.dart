class StudentMapper {
  static bool mapIsAbsent(Map<String, dynamic> json) {
    // Check both 'status' and potential boolean flags from API
    final status = json['status']?.toString().toLowerCase();
    final isAbsentFlag = json['is_absent'] == true || json['isAbsent'] == true;
    
    // If the server explicitly provides a trip-aware absence flag, use it primarily.
    if (json.containsKey('is_absent') || json.containsKey('isAbsent')) {
      return isAbsentFlag;
    }

    // Fallback logic for basic status or broad request presence
    final hasRequest = json['has_absence_request'] == true;
    return ['absent', 'absence_requested', 'غياب'].contains(status) || 
           isAbsentFlag || 
           hasRequest;
  }
}
