<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
         app()[\Spatie\Permission\PermissionRegistrar::class]
            ->forgetCachedPermissions();

        // Permissions
        Permission::create(['name' => 'users.view']);
        Permission::create(['name' => 'users.create']);
        Permission::create(['name' => 'users.edit']);
        Permission::create(['name' => 'users.delete']);

        Permission::create(['name' => 'communes.view']);
        Permission::create(['name' => 'communes.create']);
        Permission::create(['name' => 'communes.edit']);
        Permission::create(['name' => 'communes.delete']);


        Permission::create(['name' => 'classes.view']);
        Permission::create(['name' => 'classes.create']);
        Permission::create(['name' => 'classes.edit']);
        Permission::create(['name' => 'classes.delete']);

        Permission::create(['name' => 'groups.view']);
        Permission::create(['name' => 'groups.create']);
        Permission::create(['name' => 'groups.edit']);
        Permission::create(['name' => 'groups.delete']);

        Permission::create(['name' => 'students.view']);
        Permission::create(['name' => 'students.create']);
        Permission::create(['name' => 'students.edit']);
        Permission::create(['name' => 'students.delete']);

        Permission::create(['name' => 'attendance.manage']);
        Permission::create(['name' => 'payments.manage']);
        Permission::create(['name' => 'reports.view']);

        // Roles
        $superAdmin = Role::create(['name' => 'super-admin']); //National level admin with all permissions
        $admin      = Role::create(['name' => 'admin']); //Wilaya level admin with limited permissions
        $supervisor = Role::create(['name' => 'supervisor']); //commune level admin with limited permissions
        $manager    = Role::create(['name' => 'manager']);  // school level admin with limited permissions
        $teacher    = Role::create(['name' => 'teacher']);  //teacher with limited permissions
        //Permissions ASSIGNMENT
        $superAdmin->givePermissionTo(Permission::all());
        $admin->givePermissionTo([
            'communes.view',
            'communes.create',
            'communes.edit',
            'communes.delete',
            'classes.view',
            'classes.create',
            'classes.edit',
            'classes.delete',
            'groups.view',
            'groups.create',
            'groups.edit',
            'groups.delete',
            'students.view',
            'students.create',
            'students.edit',
            'students.delete',
            'attendance.manage',
            'payments.manage',
            'reports.view'
        ]);
        $supervisor->givePermissionTo([
            'communes.view','classes.view','classes.create','classes.edit','classes.delete',
            'groups.view','groups.create','groups.edit','groups.delete',
            'students.view','students.create','students.edit','students.delete',
            'attendance.manage',
            'payments.manage',
            'reports.view'
        ]);
        $manager->givePermissionTo([
            'classes.view',
            'groups.view','groups.create','groups.edit','groups.delete',
            'students.view','students.create','students.edit','students.delete',
            'attendance.manage',
            'payments.manage',
            'reports.view'
        ]);
        $teacher->givePermissionTo([
            'students.view','students.create','students.edit','students.delete',
            'attendance.manage',
            'payments.manage',
            'reports.view'
        ]);
        

    }
}
