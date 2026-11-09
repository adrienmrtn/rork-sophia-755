import type { Metadata } from "next";
import { ReaderStory } from "@/components/ReaderStory";
import { Blocker } from "@/components/Blocker";
import { QuizDemo } from "@/components/QuizDemo";
import { Proof } from "@/components/Proof";
import { Faq, FinalCta, Testimonials } from "@/components/Closing";

export const metadata: Metadata = {
  title: "La méthode · Sophia",
  description: "Lire dix minutes, retenir avec un quiz, revenir le lendemain. Et vos apps bloquées tant que le cours du jour n'est pas lu.",
};

export default function MethodPage() {
  return (
    <>
      <ReaderStory />
      <Blocker />
      <QuizDemo />
      <Proof />
      <Testimonials />
      <Faq />
      <FinalCta />
    </>
  );
}
