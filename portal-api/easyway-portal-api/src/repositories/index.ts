import { UsersRepo, OnboardingRepo, NotificationsRepo, AgentChatRepo } from "./types";
import { SqlUsersRepo } from "./sql/usersRepo.sql";
import { MockUsersRepo } from "./mock/usersRepo.mock";
import { SqlNotificationsRepo } from "./sql/notificationsRepo.sql";
import { MockNotificationsRepo } from "./mock/notificationsRepo.mock";
import { SqlAgentChatRepo } from "./sql/agentChatRepo.sql";
import { MockAgentChatRepo } from "./mock/agentChatRepo.mock";

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
