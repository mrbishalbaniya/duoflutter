export interface Profile {
  id?: number;
  user_id?: number;
  full_name: string;
  age?: number | string | null;
  gender?: string;
  bio?: string;
  location?: string;
  education?: string;
  occupation?: string;
  religion?: string;
  photo_url?: string | null;
  photo_urls?: string[];
  lifestyle_tags?: string[];
  is_verified?: boolean;
  is_onboarded?: boolean;
  profile_completeness?: number;
  pref_age_min?: number;
  pref_age_max?: number;
  pref_gender?: "everyone" | "women" | "men";
  pref_location?: string;
  pref_max_distance_km?: number;
  pref_relationship_goal?: "everyone" | "serious" | "casual" | "dating";
  pref_verified_only?: boolean;
  relationship_goal?: "serious" | "casual" | "dating" | "";
  is_premium?: boolean;
  subscription_expires_at?: string | null;
  preview_distance_km?: number | null;
}

export interface User {
  id: number;
  username: string;
  email?: string;
  profile: Profile;
}

export interface AuthTokens {
  access: string;
  refresh: string;
}

export interface LoginResponse extends AuthTokens {
  user?: User;
}

export interface RegisterResponse {
  tokens: AuthTokens;
  user?: User;
}

export type SwipeAction = "LIKE" | "SKIP" | "SUPERLIKE";

export interface Match {
  id: number;
  compatibility_score: number;
  matched_at: string;
  other_user_profile: Profile;
}

export interface SwipeResponse {
  is_match?: boolean;
  match?: Match;
  action?: SwipeAction;
}

export interface LikedProfile {
  swipe_id?: number;
  profile: Profile;
  liked_at?: string;
  action?: SwipeAction;
  locked?: boolean;
}

export interface LikesYouResponse {
  is_premium?: boolean;
  premium_required?: boolean;
  count?: number;
  results: LikedProfile[];
  locked_count?: number;
}

export interface Message {
  id: number;
  content: string;
  image_url?: string;
  timestamp: string;
  created_at?: string;
  is_read: boolean;
  sender_name: string;
  sender_photo?: string;
  is_mine: boolean;
}

export interface Conversation {
  id: number;
  match_id?: number;
  other_user_profile: Profile;
  other_user_nickname?: string;
  last_message?: Message | string | null;
  last_message_at?: string;
  updated_at?: string;
  created_at?: string;
  unread_count?: number;
  is_other_user_typing?: boolean;
}

export type ThemeMode = "dark" | "light" | "system";

export interface SubscriptionPlan {
  plan_id: string;
  name: string;
  description: string;
  currency: string;
  amount: number;
  duration_days: number;
  badge?: string | null;
}

export interface EsewaPaymentForm {
  amount: string;
  tax_amount: string;
  total_amount: string;
  transaction_uuid: string;
  product_code: string;
  product_service_charge: string;
  product_delivery_charge: string;
  success_url: string;
  failure_url: string;
  signed_field_names: string;
  signature: string;
}

export interface InitiateSubscriptionResponse {
  payment_url: string;
  transaction_uuid: string;
  form: EsewaPaymentForm;
}

export type VerificationStatus = "PENDING" | "VERIFIED" | "REJECTED" | "UNDER_REVIEW";

export interface VerificationStartResponse {
  session_id: string;
  session_token: string;
  expires_at: string;
  instructions: string[];
  liveness_steps: string[];
}

export interface VerificationStatusResponse {
  status: VerificationStatus;
  similarity_score: number;
  liveness_score: number;
  fraud_probability: number;
  verified_badge: boolean;
  rejection_reasons?: string[];
}
