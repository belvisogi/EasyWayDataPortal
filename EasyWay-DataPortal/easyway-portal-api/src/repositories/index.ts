import { UsersRepo, OnboardingRepo } from "./types";
import { SqlUsersRepo } from "./sql/usersRepo.sql";
import { MockUsersRepo } from "./mock/usersRepo.mock";

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

