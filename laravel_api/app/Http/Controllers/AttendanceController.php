<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Attendance;

class AttendanceController extends Controller
{
    public function index($sessionId)
{
    $attendances = Attendance::where('session_id', $sessionId)->with('student')->get();
    return response()->json($attendances);
}

public function store(Request $request, $sessionId)
{
    // Check if bulk 'attendance' data is sent
    if ($request->has('attendance')) {
        $attendanceList = $request->input('attendance');

        foreach ($attendanceList as $attendanceData) {
            Attendance::updateOrCreate(
                [
                    'session_id' => $sessionId,
                    'student_id' => $attendanceData['student_id'],
                ],
                [
                    'status' => $attendanceData['status'] ?? 'present',
                ]
            );
        }

        return response()->json([
            'message' => 'Bulk attendance saved successfully!',
            'status' => 'success'
        ], 201);
    }

    // for single update
    $validated = $request->validate([
        'student_id' => 'required|exists:students,id',
        'status' => 'required|string|in:present,absent,late',
    ]);

    $validated['session_id'] = $sessionId;

    $attendance = Attendance::create($validated);

    return response()->json($attendance, 201);
}


public function update(Request $request, $sessionId, $attendanceId)
{
    $validated = $request->validate([
        'status' => 'required|string|in:present,absent,late', // or whatever statuses you support
    ]);

    $attendance = Attendance::where('session_id', $sessionId)->findOrFail($attendanceId);

    $attendance->update($validated);

    return response()->json($attendance);
}

public function destroy($sessionId, $attendanceId)
{
    $attendance = Attendance::where('session_id', $sessionId)->findOrFail($attendanceId);
    $attendance->delete();

    return response()->json(null, 204);
}

}
