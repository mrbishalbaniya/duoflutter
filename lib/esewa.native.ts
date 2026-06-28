import { Alert, Linking } from "react-native";
import type { EsewaPaymentForm } from "@/types";

export function formatNpr(amount: number): string {
  return new Intl.NumberFormat("en-NP", {
    style: "currency",
    currency: "NPR",
    maximumFractionDigits: 0,
  }).format(amount);
}

export function submitEsewaPayment(paymentUrl: string, _form: EsewaPaymentForm): void {
  void Linking.openURL(paymentUrl).catch(() => {
    Alert.alert(
      "eSewa payment",
      "Complete payment in a browser. Open Duo in Expo web on your computer for the full checkout flow."
    );
  });
}
