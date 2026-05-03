"""add_siem_honeypot_biometrics_mesh_er_models

Revision ID: 002_siem_honeypot_biometrics
Revises: 001_initial
Create Date: 2026-05-03 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ENUM as PG_ENUM

# revision identifiers
revision = "002_siem_honeypot_biometrics"
down_revision = "001_initial"
branch_labels = None
depends_on = None


def upgrade():
    # Honeypot Case
    op.add_column("cases", sa.Column("is_honeypot", sa.Boolean(), server_default="false", nullable=False))

    # Behavioral Biometrics
    op.create_table(
        "behavioral_biometrics",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("agent_id", sa.String(), sa.ForeignKey("agent_profiles.id"), nullable=True),
        sa.Column("typing_speed", sa.Float(), nullable=True),
        sa.Column("usage_hour", sa.Integer(), nullable=True),
        sa.Column("location_variance", sa.Float(), nullable=True),
        sa.Column("tap_pressure_avg", sa.Float(), nullable=True),
        sa.Column("swipe_speed_avg", sa.Float(), nullable=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # Mesh Messages
    op.create_table(
        "mesh_messages",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sender_node_id", sa.String(), nullable=False),
        sa.Column("recipient_agent_id", sa.String(), sa.ForeignKey("agent_profiles.id"), nullable=True),
        sa.Column("payload", sa.Text(), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("status", sa.String(), server_default="pending", nullable=False),
    )

    # HUMINT Sources (Entity Resolution)
    op.create_table(
        "humint_sources",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(), unique=True, nullable=False),
        sa.Column("fuzzy_match_score", sa.Float(), nullable=True),
        sa.Column("duplicate_of_id", sa.Integer(), sa.ForeignKey("humint_sources.id"), nullable=True),
        sa.Column("reliability_rating", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # Agent last checkin
    op.add_column("agent_profiles", sa.Column("last_checkin", sa.DateTime(timezone=True), nullable=True))


def downgrade():
    op.drop_column("cases", "is_honeypot")
    op.drop_table("behavioral_biometrics")
    op.drop_table("mesh_messages")
    op.drop_table("humint_sources")
    op.drop_column("agent_profiles", "last_checkin")
