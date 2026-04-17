"""Migracion inicial — crea todas las tablas del schema IMC.

Revision ID: 001_initial
Revises:
Create Date: 2026-04-17
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = "001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # users
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("username", sa.String(), nullable=False),
        sa.Column("role", sa.String(), nullable=False),
        sa.Column("classification_level", sa.String(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("assigned_cases", sa.JSON(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)

    # agent_profiles
    op.create_table(
        "agent_profiles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("entity_id", sa.String(), nullable=False),
        sa.Column("role", sa.String(), nullable=False),
        sa.Column("classification_level", sa.String(), nullable=False),
        sa.Column("assigned_cases", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(), nullable=False, server_default="ACTIVE"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column("last_seen", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_agent_profiles_entity_id", "agent_profiles", ["entity_id"], unique=True)

    # cases
    op.create_table(
        "cases",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("sensitivity_level", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # source_profiles
    op.create_table(
        "source_profiles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("pseudonym", sa.String(), nullable=False),
        sa.Column("reliability_rating", sa.Integer(), nullable=True),
        sa.Column("sensitivity_level", sa.String(), nullable=True),
        sa.Column("case_linked", sa.String(), nullable=True),
        sa.Column("contact_channel_type", sa.String(), nullable=True),
        sa.Column("handler_assigned", sa.String(), nullable=True),
        sa.Column("risk_score", sa.Float(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["case_linked"], ["cases.id"]),
        sa.ForeignKeyConstraint(["handler_assigned"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("pseudonym"),
    )
    op.create_index("ix_source_profiles_case_linked", "source_profiles", ["case_linked"])
    op.create_index("ix_source_profiles_handler_assigned", "source_profiles", ["handler_assigned"])

    # intel_packages
    op.create_table(
        "intel_packages",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("case_id", sa.String(), nullable=False),
        sa.Column("classification_level", sa.String(), nullable=False),
        sa.Column("source_profile_id", sa.String(), nullable=True),
        sa.Column("confidence_score", sa.Float(), nullable=True),
        sa.Column("location_lat", sa.Float(), nullable=True),
        sa.Column("location_lon", sa.Float(), nullable=True),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column("tags", sa.JSON(), nullable=True),
        sa.Column("dissemination_policy", sa.String(), nullable=True),
        sa.Column("content_encrypted", sa.Text(), nullable=True),
        sa.Column("hash_integrity", sa.String(), nullable=True),
        sa.Column("created_by", sa.String(), nullable=True),
        sa.Column("access_log_reference", sa.String(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["case_id"], ["cases.id"]),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["source_profile_id"], ["source_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_intel_packages_case_id", "intel_packages", ["case_id"])
    op.create_index("ix_intel_packages_created_by", "intel_packages", ["created_by"])
    op.create_index("ix_intel_packages_source_profile_id", "intel_packages", ["source_profile_id"])

    # access_logs
    op.create_table(
        "access_logs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("action", sa.String(), nullable=False),
        sa.Column("resource_id", sa.String(), nullable=False),
        sa.Column(
            "timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("reason_code", sa.String(), nullable=True),
        sa.Column("device_id", sa.String(), nullable=True),
        sa.Column("integrity_hash", sa.String(), nullable=False),
        sa.Column("previous_hash", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("integrity_hash"),
    )
    op.create_index("ix_access_logs_user_id", "access_logs", ["user_id"])

    # wearable_devices
    op.create_table(
        "wearable_devices",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=False),
        sa.Column("agent_id", sa.String(), nullable=True),
        sa.Column("device_type", sa.String(), nullable=True),
        sa.Column("last_heartbeat", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("config", sa.JSON(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["agent_id"], ["agent_profiles.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("device_id"),
    )
    op.create_index("ix_wearable_devices_agent_id", "wearable_devices", ["agent_id"])
    op.create_index("ix_wearable_devices_device_id", "wearable_devices", ["device_id"])

    # wearable_events
    op.create_table(
        "wearable_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=True),
        sa.Column("agent_id", sa.String(), nullable=True),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("payload_encrypted", sa.Text(), nullable=True),
        sa.Column("location_lat", sa.Float(), nullable=True),
        sa.Column("location_lon", sa.Float(), nullable=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("processed", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["agent_id"], ["agent_profiles.id"]),
        sa.ForeignKeyConstraint(["device_id"], ["wearable_devices.device_id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_wearable_events_device_id", "wearable_events", ["device_id"])
    op.create_index("ix_wearable_events_agent_id", "wearable_events", ["agent_id"])

    # mobile_reports
    op.create_table(
        "mobile_reports",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("agent_id", sa.String(), nullable=True),
        sa.Column("case_id", sa.String(), nullable=True),
        sa.Column("report_type", sa.String(), nullable=False),
        sa.Column("content_encrypted", sa.Text(), nullable=True),
        sa.Column("classification", sa.String(), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("device_fingerprint", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="RECEIVED"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["agent_id"], ["agent_profiles.id"]),
        sa.ForeignKeyConstraint(["case_id"], ["cases.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_mobile_reports_agent_id", "mobile_reports", ["agent_id"])
    op.create_index("ix_mobile_reports_case_id", "mobile_reports", ["case_id"])


def downgrade() -> None:
    op.drop_table("mobile_reports")
    op.drop_table("wearable_events")
    op.drop_table("wearable_devices")
    op.drop_table("access_logs")
    op.drop_table("intel_packages")
    op.drop_table("source_profiles")
    op.drop_table("cases")
    op.drop_table("agent_profiles")
    op.drop_table("users")
