import uuid
from pydantic import BaseModel, ConfigDict, Field


# -------------------- Overview Schemas --------------------

class StreakInfo(BaseModel):
    current_streak: int = 0
    longest_streak: int = 0


class PersonalRecordsRead(BaseModel):
    best_day_tasks: int = 0
    best_day_focus_minutes: int = 0
    longest_streak: int = 0


class GoalAnalyticsRead(BaseModel):
    active_goals: int = 0
    completed_goals: int = 0
    total_goals: int = 0
    goal_completion_rate: float = 0.0
    completed_milestones: int = 0
    total_milestones: int = 0
    milestone_completion_rate: float = 0.0


class FocusTimeRead(BaseModel):
    today_minutes: int = 0
    week_minutes: int = 0
    month_minutes: int = 0


class ProductivityInsightsRead(BaseModel):
    most_productive_day: str = "N/A"
    most_productive_window: str = "N/A"
    most_productive_window_percentage: float = 0.0


class CompletionStatsRead(BaseModel):
    total_completed_tasks: int = 0
    total_due_tasks: int = 0
    overall_completion_rate: float = 0.0
    on_time_completion_rate: float = 0.0
    overdue_completion_rate: float = 0.0


class AnalyticsOverviewRead(BaseModel):
    streaks: StreakInfo
    personal_records: PersonalRecordsRead
    goals_summary: GoalAnalyticsRead
    focus_time: FocusTimeRead
    productivity_insights: ProductivityInsightsRead
    completion_stats: CompletionStatsRead

    model_config = ConfigDict(from_attributes=True)


# -------------------- Weekly Velocity Schemas --------------------

class WeeklyVelocityDay(BaseModel):
    date: str
    day_label: str  # Mon, Tue, Wed...
    completed_count: int = 0
    total_due_count: int = 0
    completion_rate: float = 0.0
    completed_minutes: int = 0


class TimeOfDayBreakdown(BaseModel):
    morning: int = 0
    afternoon: int = 0
    evening: int = 0
    night: int = 0


class WeeklyAnalyticsRead(BaseModel):
    days: list[WeeklyVelocityDay] = []
    time_of_day_breakdown: TimeOfDayBreakdown

    model_config = ConfigDict(from_attributes=True)


# -------------------- Breakdown Schemas --------------------

class CategoryBreakdownItem(BaseModel):
    category_id: uuid.UUID | None = None
    name: str
    color: str = "#6366F1"
    count: int = 0
    percentage: float = 0.0


class PriorityBreakdown(BaseModel):
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0


class AnalyticsBreakdownRead(BaseModel):
    categories: list[CategoryBreakdownItem] = []
    priorities: PriorityBreakdown

    model_config = ConfigDict(from_attributes=True)


# -------------------- Heatmap Schemas --------------------

class HeatmapDayItem(BaseModel):
    date: str
    count: int = 0
    level: int = 0  # 0: 0 tasks, 1: 1-2, 2: 3-4, 3: 5-6, 4: 7+ tasks


class AnalyticsHeatmapRead(BaseModel):
    heatmap: list[HeatmapDayItem] = []

    model_config = ConfigDict(from_attributes=True)
