<?php
require 'c:/laragon/www/masarat-wasel-dashboards-new/vendor/autoload.php';
$app = require_once 'c:/laragon/www/masarat-wasel-dashboards-new/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
$teacher = \App\Models\User::where('role', 'teacher')->first();
if($teacher) {
    echo "Teacher: {$teacher->name}\n";
    echo "School ID: {$teacher->school_id}\n";
    $school = \App\Models\School::find($teacher->school_id);
    echo "School Name: " . ($school ? $school->name : "none") . "\n";
    $cls = \DB::table('classroom_teacher')->where('teacher_id', $teacher->id)->get();
    echo "Classrooms empty? " . ($cls->isEmpty() ? 'Yes' : 'No') . "\n";
    foreach($cls as $c) {
       echo "- School ID on pivot: {$c->school_id}\n";
    }
}
