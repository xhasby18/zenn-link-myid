const addCounter = async (req, res, next) => {
  try {
    await fetch(
      "https://api-zenn.vercel.app/api/tool/counter?q=zenn_my_id_web_counter&secret=cat_lover_c2VjcmV0"
    );
    next();
  } catch (error) {
    console.log(error);
  }
};

export default addCounter;
