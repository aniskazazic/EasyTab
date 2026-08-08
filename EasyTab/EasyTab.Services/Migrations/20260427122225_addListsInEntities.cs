using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyTab.Services.Migrations
{
    /// <inheritdoc />
    public partial class addListsInEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserRoles_Roles_RoleId' AND parent_object_id = OBJECT_ID('UserRoles'))
                    ALTER TABLE [UserRoles] DROP CONSTRAINT [FK_UserRoles_Roles_RoleId];

                IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserRoles_Users_UserId' AND parent_object_id = OBJECT_ID('UserRoles'))
                    ALTER TABLE [UserRoles] DROP CONSTRAINT [FK_UserRoles_Users_UserId];

                IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__UserRoles__RoleI__45F365D3' AND parent_object_id = OBJECT_ID('UserRoles'))
                    ALTER TABLE [UserRoles] DROP CONSTRAINT [FK__UserRoles__RoleI__45F365D3];

                IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK__UserRoles__UserI__44FF419A' AND parent_object_id = OBJECT_ID('UserRoles'))
                    ALTER TABLE [UserRoles] DROP CONSTRAINT [FK__UserRoles__UserI__44FF419A];
                """);

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles",
                column: "RoleId",
                principalTable: "Roles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__RoleI__45F365D3",
                table: "UserRoles");

            migrationBuilder.DropForeignKey(
                name: "FK__UserRoles__UserI__44FF419A",
                table: "UserRoles");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRoles_Roles_RoleId",
                table: "UserRoles",
                column: "RoleId",
                principalTable: "Roles",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRoles_Users_UserId",
                table: "UserRoles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
