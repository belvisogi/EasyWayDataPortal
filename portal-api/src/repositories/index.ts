import { UsersRepo, OnboardingRepo, NotificationsRepo, AgentChatRepo, AppointmentsRepo, QuotesRepo } from "./types";
import { SqlUsersRepo } from "./sql/usersRepo.sql";
import { MockUsersRepo } from "./mock/usersRepo.mock";
import { SqlNotificationsRepo } from "./sql/notificationsRepo.sql";
import { MockNotificationsRepo } from "./mock/notificationsRepo.mock";
import { SqlAgentChatRepo } from "./sql/agentChatRepo.sql";
import { MockAgentChatRepo } from "./mock/agentChatRepo.mock";
import { SqlAppointmentsRepo } from "./sql/appointmentsRepo.sql";
import { MockAppointmentsRepo } from "./mock/appointmentsRepo.mock";
import { SqlQuotesRepo } from "./sql/quotesRepo.sql";
import { MockQuotesRepo } from "./mock/quotesRepo.mock";

function getDbMode(): string {
  const v = (process.env.DB_MODE || "sql").toLowerCase();
  return v === "mock" ? "mock" : "sql";
}

export function getUsersRepo(): UsersRepo {
  return getDbMode() === "mock" ? new MockUsersRepo() : new SqlUsersRepo();
}

export function getOnboardingRepo(): OnboardingRepo {
  // For now both Users and Onboarding live in same class per backend
  return (getDbMode() === "mock" ? new MockUsersRepo() : new SqlUsersRepo()) as unknown as OnboardingRepo;
}

export function getNotificationsRepo(): NotificationsRepo {
  return getDbMode() === "mock" ? new MockNotificationsRepo() : new SqlNotificationsRepo();
}

export function getAgentChatRepo(): AgentChatRepo {
  return getDbMode() === "mock" ? new MockAgentChatRepo() : new SqlAgentChatRepo();
}

export function getAppointmentsRepo(): AppointmentsRepo {
  return getDbMode() === "mock" ? new MockAppointmentsRepo() : new SqlAppointmentsRepo();
}

export function getQuotesRepo(): QuotesRepo {
  return getDbMode() === "mock" ? new MockQuotesRepo() : new SqlQuotesRepo();
}
